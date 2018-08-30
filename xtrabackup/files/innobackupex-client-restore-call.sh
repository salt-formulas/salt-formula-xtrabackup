{%- from "xtrabackup/map.jinja" import client with context %}
#!/bin/sh

# Purpuse of this script is to locally prepare appropriate backup to restore from local or remote location

{%- if client.restore_from == 'remote' %}
LOGDIR=/var/log/backups
mkdir -p $LOGDIR
scpLog=/var/log/backups/innobackupex-restore-scp.log
echo "Adding ssh-key of remote host to known_hosts"
ssh-keygen -R {{ client.target.host }} 2>&1 | > $scpLog
ssh-keyscan {{ client.target.host }} >> ~/.ssh/known_hosts  2>&1 | >> $scpLog
REMOTEBACKUPPATH=`ssh xtrabackup@{{ client.target.host }} "/usr/local/bin/innobackupex-restore-call.sh {{ client.restore_full_latest }}"`
echo "Calling /usr/local/bin/innobackupex-restore.sh $REMOTEBACKUPPATH and getting the backup files from remote host"
/usr/local/bin/innobackupex-restore.sh $REMOTEBACKUPPATH

{%- else %}

BACKUPDIR={{ client.backup_dir }} # Backups base directory
FULL=`find $BACKUPDIR/full -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -{{ client.restore_full_latest }} | tail -1`
FULL_INCR=`find $BACKUPDIR/incr -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -{{ client.restore_full_latest }} | tail -1`
BEFORE_NEXT_FULL_INCR=`find $BACKUPDIR/incr -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -$(( {{ client.restore_full_latest }} - 1 )) | tail -1`

if [ -z "$FULL" ]; then
    echo "Error: No local backup found in $BACKUPDIR/full" >&2
    exit 1
fi

if [ -z "$BEFORE_NEXT_FULL_INCR" ]; then
    BEFORE_NEXT_FULL_INCR="Empty"
fi

if [ "$FULL" = "$FULL_INCR" ]; then
  LATEST_FULL_INCR=`find $BACKUPDIR/incr/$FULL_INCR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1 | tail -1`
  echo "Restoring full backup $FULL starting from its latest incremental $LATEST_FULL_INCR"
  echo "Calling /usr/local/bin/innobackupex-restore.sh $BACKUPDIR/incr/$FULL/$LATEST_FULL_INCR"
  echo
  /usr/local/bin/innobackupex-restore.sh $BACKUPDIR/incr/$FULL_INCR/$LATEST_FULL_INCR
elif [ "$FULL" = "$BEFORE_NEXT_FULL_INCR" ]; then
  LATEST_FULL_INCR=`find $BACKUPDIR/incr/$BEFORE_NEXT_FULL_INCR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1 | tail -1`
  echo "Restoring full backup $FULL starting from its latest incremental $LATEST_FULL_INCR"
  echo "Calling /usr/local/bin/innobackupex-restore.sh $BACKUPDIR/incr/$FULL/$LATEST_FULL_INCR"
  echo
  /usr/local/bin/innobackupex-restore.sh $BACKUPDIR/incr/$FULL/$LATEST_FULL_INCR
else
  echo "Restoring full backup $FULL"
  echo "Calling /usr/local/bin/innobackupex-restore.sh $BACKUPDIR/full/$FULL"
  echo
  /usr/local/bin/innobackupex-restore.sh $BACKUPDIR/full/$FULL
fi

{%- endif %}
