{%- from "xtrabackup/map.jinja" import client with context %}
#!/bin/sh
# 
# Script to create full and incremental backups (for all databases on server) using innobackupex from Percona.
# http://www.percona.com/doc/percona-xtrabackup/innobackupex/innobackupex_script.html
#
# Every time it runs will generate an incremental backup except for the first time (full backup).
# FULLBACKUPLIFE variable will define your full backups schedule.

USEROPTIONS="--user={{ client.database.user }} --password={{ client.database.password }} --socket=/var/run/mysqld/mysqld.sock"
#TMPFILE="/var/log/backups/innobackupex-runner.$$.tmp"
LOGDIR=/var/log/backups
TMPFILE="/var/log/backups/innobackupex-runner.log"
MYCNF=/etc/mysql/my.cnf
MYSQL=/usr/bin/mysql
MYSQLADMIN=/usr/bin/mysqladmin
BACKUPDIR={{ client.backup_dir }} # Backups base directory
FULLBACKUPDIR=$BACKUPDIR/full # Full backups directory
INCRBACKUPDIR=$BACKUPDIR/incr # Incremental backups directory
HOURSFULLBACKUPLIFE={{ client.hours_before_full }} # Lifetime of the latest full backup in hours
FULLBACKUPLIFE=$(( $HOURSFULLBACKUPLIFE * 60 * 60 ))
KEEP={{ client.full_backups_to_keep }} # Number of full backups (and its incrementals) to keep
rsyncLog=/var/log/backups/innobackupex-rsync.log

{%- if client.compression is defined %}
compression={{ client.compression }}
{%- else %}
compression=false
{%- endif %}

{%- if client.compression_threads is defined %}
compression_threads={{ client.compression_threads }}
{%- else %}
compression_threads=1
{%- endif %}

mkdir -p $LOGDIR

# Grab start time
STARTED_AT=`date +%s`

#############################################################################
# Display error message and exit
#############################################################################
error()
{
	echo "$1" 1>&2
	exit 1
}

# Check prerequisites before proceeding
if [ ! -d $BACKUPDIR ]; then
  error "Backup destination folder: $BACKUPDIR does not exist."
fi

if [ -z "`$MYSQLADMIN $USEROPTIONS status | grep 'Uptime'`" ] ; then
 error "HALTED: MySQL does not appear to be running."
fi

if ! `echo 'exit' | $MYSQL -s $USEROPTIONS` ; then
 error "HALTED: Supplied mysql username or password appears to be incorrect (not copied here for security, see script)."
fi

# Some info output
echo "----------------------------"
echo
echo "$0: MySQL backup script"
echo "started: `date`"
echo

# Create full and incr backup directories if they not exist.
mkdir -p $FULLBACKUPDIR
mkdir -p $INCRBACKUPDIR

# Find latest full backup
LATEST_FULL=`find $FULLBACKUPDIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1`

# Get latest backup last modification time
LATEST_FULL_CREATED_AT=`stat -c %Y $FULLBACKUPDIR/$LATEST_FULL`

# If compression is enabled, pass it on to the backup command
if [ "$compression" = True ]; then
  compress="--compress"
  compression_threads="--compress-threads=$compression_threads"
  echo "Setting compression to True"
  echo
else
  compress=
  compression_threads=
fi

# Run an incremental backup if latest full is still valid. Otherwise, run a new full one.
if [ "$LATEST_FULL" -a `expr $LATEST_FULL_CREATED_AT + $FULLBACKUPLIFE + 5` -ge $STARTED_AT ] ; then
  # Create incremental backups dir if not exists.
  TMPINCRDIR=$INCRBACKUPDIR/$LATEST_FULL
  mkdir -p $TMPINCRDIR

  # Find latest incremental backup.
  LATEST_INCR=`find $TMPINCRDIR -mindepth 1 -maxdepth 1 -type d | sort -nr | head -1`

  # If this is the first incremental, use the full as base. Otherwise, use the latest incremental as base.
  if [ ! $LATEST_INCR ] ; then
    INCRBASEDIR=$FULLBACKUPDIR/$LATEST_FULL
  else
    INCRBASEDIR=$LATEST_INCR
  fi

  echo "Running new incremental backup using $INCRBASEDIR as base."
  innobackupex --defaults-file=$MYCNF $USEROPTIONS $compress $compression_threads --incremental $TMPINCRDIR --incremental-basedir $INCRBASEDIR > $TMPFILE 2>&1
else
  echo "Running new full backup."
  innobackupex --defaults-file=$MYCNF $USEROPTIONS $compress $compression_threads $FULLBACKUPDIR > $TMPFILE 2>&1
fi

if [ -z "`tail -1 $TMPFILE | grep 'completed OK!'`" ] ; then
 echo "$INNOBACKUPEX failed:"; echo
 echo "---------- ERROR OUTPUT from $INNOBACKUPEX ----------"
 cat $TMPFILE
 #rm -f $TMPFILE
 exit 1
fi

THISBACKUP=`awk -- "/Backup created in directory/ { split( \\\$0, p, \"'\" ) ; print p[2] }" $TMPFILE`
#rm -f $TMPFILE

echo "Databases backed up successfully to: $THISBACKUP"
echo

# rsync just the new or modified backup files
{%- if client.target is defined %}
echo "Adding ssh-key of remote host to known_hosts"
ssh-keygen -R {{ client.target.host }} 2>&1 | > $rsyncLog
ssh-keyscan {{ client.target.host }} >> ~/.ssh/known_hosts  2>&1 | >> $rsyncLog
echo "Rsyncing files to remote host"
/usr/bin/rsync -rhtPv --rsync-path=rsync --progress $BACKUPDIR/* -e ssh xtrabackup@{{ client.target.host }}:$BACKUPDIR >> $rsyncLog

# Check if the rsync succeeded or failed
if ! grep -q "rsync error: " $rsyncLog; then
        echo "Rsync to remote host completed OK"
else
        echo "Rsync to remote host FAILED"
        exit 1
fi
{%- endif %}


# Cleanup
echo "Cleanup. Keeping only $KEEP full backups and its incrementals."
AGE=$(($FULLBACKUPLIFE * $KEEP / 60))
find $FULLBACKUPDIR -maxdepth 1 -type d -mmin +$AGE -execdir echo "removing: "$FULLBACKUPDIR/{} \; -execdir rm -rf $FULLBACKUPDIR/{} \; -execdir echo "removing: "$INCRBACKUPDIR/{} \; -execdir rm -rf $INCRBACKUPDIR/{} \;

echo
echo "completed: `date`"
exit 0
