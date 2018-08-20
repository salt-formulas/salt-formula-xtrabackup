{%- from "xtrabackup/map.jinja" import client with context %}
{%- from "xtrabackup/map.jinja" import server with context %}
#!/bin/sh
#
# Script to prepare and restore full and incremental backups created with innobackupex-runner.
#
# usage example for incr backup restore: ./restore.sh /var/backups/mysql/xtrabackup/incr/2017-05-24_19-48-10/2017-05-24_19-55-35/

#TMPFILE="/var/log/backups/innobackupex-restore.$$.tmp"
TMPFILE="/var/log/backups/innobackupex-restore.log"
MYCNF=/etc/mysql/my.cnf
BACKUPDIR={{ client.backup_dir }} # Backups base directory
FULLBACKUPDIR=$BACKUPDIR/full # Full backups directory
INCRBACKUPDIR=$BACKUPDIR/incr # Incremental backups directory
MEMORY=1024M # Amount of memory to use when preparing the backup
DBALREADYRESTORED=$BACKUPDIR/dbrestored
scpLog=/var/log/backups/innobackupex-restore-scp.log
decompressionLog=/var/log/backups/innobackupex-decompression.log
compression=false
LOGDIR=/var/log/backups

mkdir -p $LOGDIR

#############################################################################
# Display error message and exit
#############################################################################
error()
{
	echo "$1" 1>&2
	exit 1
}

#############################################################################
# Check for errors in innobackupex output
#############################################################################
check_innobackupex_error()
{
	if [ -z "`tail -1 $TMPFILE | grep 'completed OK!'`" ] ; then
    echo "$INNOBACKUPEX failed:"; echo
    echo "---------- ERROR OUTPUT from $INNOBACKUPEX ----------"
    cat $TMPFILE
    #rm -f $TMPFILE
    exit 1
  fi
}

# Check options before proceeding
if [ -e $DBALREADYRESTORED ]; then
  error "Databases already restored. If you want to restore again delete $DBALREADYRESTORED file and run the script again."
fi

if [ ! -d $BACKUPDIR ]; then
  error "Backup destination folder: $BACKUPDIR does not exist."
fi

if [ $# != 1 ] ; then
  error "Usage: $0 /absolute/path/to/backup/to/restore"
fi

{%- if client.restore_from != 'remote' %}

if [ ! -d $1 ]; then
  error "Backup to restore: $1 does not exist."
fi

{%- endif %}

# Some info output
echo "----------------------------"
echo
echo "$0: MySQL backup script"
echo "started: `date`"
echo

{%- if client.restore_from == 'remote' %}
#get files from remote and change variables to local restore dir

LOCALRESTOREDIR=/var/backups/restoreMysql
REMOTE_PARENT_DIR=`dirname $1`
BACKUPPATH=$1
FULLBACKUPDIR=$LOCALRESTOREDIR/full
INCRBACKUPDIR=$LOCALRESTOREDIR/incr

mkdir -p $LOCALRESTOREDIR
rm -rf $LOCALRESTOREDIR/*

echo "Getting files from remote host"

case "$BACKUPPATH" in
  *incr*) echo "SCP getting full and incr backup files";
          FULL=`basename $REMOTE_PARENT_DIR`;
          mkdir -p $FULLBACKUPDIR;
          mkdir -p $INCRBACKUPDIR;
          PARENT_DIR=$INCRBACKUPDIR/$FULL;
          `scp -rp xtrabackup@{{ client.target.host }}:$REMOTE_PARENT_DIR/ $INCRBACKUPDIR/ >> $scpLog 2>&1`;
          `scp -rp xtrabackup@{{ client.target.host }}:{{ server.backup_dir }}/full/$FULL/ $FULLBACKUPDIR/$FULL/ >> $scpLog 2>&1`;;
  *full*) echo "SCP getting full backup files";
          FULL=`basename $1`;
          mkdir -p $FULLBACKUPDIR;
          PARENT_DIR=$FULLBACKUPDIR;
          `scp -rp xtrabackup@{{ client.target.host }}:{{ server.backup_dir }}/full/$FULL/ $FULLBACKUPDIR/$FULL/  >> $scpLog 2>&1`;;
  *)      echo "Unable to scp backup files from remote host"; exit 1 ;;
esac

# Check if the scp succeeded or failed
if ! grep -q "No such file or directory" $scpLog; then
        echo "SCP from remote host completed OK"
else
        echo "SCP from remote host FAILED"
        exit 1
fi

{%- else %}

PARENT_DIR=`dirname $1`

{%- endif %}

if [ $PARENT_DIR = $FULLBACKUPDIR ]; then
{%- if client.restore_from == 'remote' %}
  FULLBACKUP=$FULLBACKUPDIR/$FULL
{%- else %}
  FULLBACKUP=$1
{%- endif %}

  for bf in `find . $FULLBACKUP -iname "*\.qp"`; do compression=True; break; done

  if [ "$compression" = True ]; then
    if hash qpress 2>>$TMPFILE;  then
        echo "qpress already installed" >> $TMPFILE
    else
{%- if client.qpress.source == 'tar' %}
        wget {{ client.qpress.name }} > $decompressionLog 2>&1
        tar -xvf qpress-11-linux-x64.tar
        cp qpress  /usr/bin/qpress
        chmod 755 /usr/bin/qpress
        chown root:root /usr/bin/qpress
{%- endif %}
    fi
    echo "Uncompressing $FULLBACKUP"
    for bf in `find . $FULLBACKUP -iname "*\.qp"`; do qpress -d $bf $(dirname $bf) && rm $bf; done > $decompressionLog 2>&1
  fi

  echo "Restore `basename $FULLBACKUP`"
  echo
else
  if [ `dirname $PARENT_DIR` = $INCRBACKUPDIR ]; then
    INCR=`basename $1`
    FULL=`basename $PARENT_DIR`
    FULLBACKUP=$FULLBACKUPDIR/$FULL


    if [ ! -d $FULLBACKUP ]; then
      error "Full backup: $FULLBACKUP does not exist."
    fi

    for bf in `find . $FULLBACKUP -iname "*\.qp"`; do compression=True; break; done

    if [ "$compression" = True ]; then
      if hash qpress 2>>$decompressionLog;  then
          echo "qpress already installed" >> $decompressionLog
      else
{%- if client.qpress.source == 'tar' %}
          wget {{ client.qpress.name }} > $decompressionLog 2>&1
          tar -xvf qpress-11-linux-x64.tar
          cp qpress  /usr/bin/qpress
          chmod 755 /usr/bin/qpress
          chown root:root /usr/bin/qpress
{%- endif %}
      fi
      echo "Uncompressing $FULLBACKUP"
      for bf in `find . $FULLBACKUP -iname "*\.qp"`; do qpress -d $bf $(dirname $bf) && rm $bf; done > $decompressionLog 2>&1
      echo "Uncompressing $PARENT_DIR"
      for bf in `find . $PARENT_DIR -iname "*\.qp"`; do qpress -d $bf $(dirname $bf) && rm $bf; done >> $decompressionLog 2>&1
    fi

    echo
    echo "Restore $FULL up to incremental $INCR"
    echo

    echo "Replay committed transactions on full backup"
    innobackupex --defaults-file=$MYCNF --apply-log --redo-only --use-memory=$MEMORY $FULLBACKUP > $TMPFILE 2>&1
    check_innobackupex_error

    # Apply incrementals to base backup
    for i in `find $PARENT_DIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -n`; do
      echo "Applying $i to full ..."
      innobackupex --defaults-file=$MYCNF --apply-log --redo-only --use-memory=$MEMORY $FULLBACKUP --incremental-dir=$PARENT_DIR/$i > $TMPFILE 2>&1
      check_innobackupex_error

      if [ $INCR = $i ]; then
        break # break. we are restoring up to this incremental.
      fi
    done
  else
    error "unknown backup type"
  fi
fi

echo "Preparing ..."
innobackupex --defaults-file=$MYCNF --apply-log --use-memory=$MEMORY $FULLBACKUP > $TMPFILE 2>&1
check_innobackupex_error

echo
echo "Restoring ..."
innobackupex --defaults-file=$MYCNF --copy-back $FULLBACKUP > $TMPFILE 2>&1
check_innobackupex_error
chown -R mysql:mysql /var/lib/mysql
#rm -f $TMPFILE
touch $DBALREADYRESTORED
echo "Backup restored successfully. You are able to start mysql now."
echo "Verify files ownership in mysql data dir."
#echo "Run 'chown -R mysql:mysql /path/to/data/dir' if necessary."
echo
echo "completed: `date`"
exit 0
{#
# vim: ft=jinja
#}
