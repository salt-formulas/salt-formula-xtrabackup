{%- from "xtrabackup/map.jinja" import server with context %}
#!/bin/sh

# This script returns appropriate backup that client will restore

if [ $# -eq 0 ]; then
    echo "No arguments provided"
    exit 1
fi

# if arg is not an integer
case $1 in
    ''|*[!0-9]*) echo "Argument must be integer"; exit 1 ;;
    *) ;;
esac

BACKUPDIR={{ server.backup_dir }} # Backups base directory
FULL=`find $BACKUPDIR/full -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -$1 | tail -1`
FULL_INCR=`find $BACKUPDIR/incr -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -$1 | tail -1`
BEFORE_NEXT_FULL_INCR=`find $BACKUPDIR/incr -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -$(( $1 - 1 )) | tail -1`

if [ -z "$BEFORE_NEXT_FULL_INCR" ]; then
    BEFORE_NEXT_FULL_INCR="Empty"
fi

if [ $FULL = $FULL_INCR ]; then
  LATEST_FULL_INCR=`find $BACKUPDIR/incr/$FULL_INCR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1 | tail -1`
  echo "$BACKUPDIR/incr/$FULL/$LATEST_FULL_INCR"
elif [ $FULL = $BEFORE_NEXT_FULL_INCR ]; then
  LATEST_FULL_INCR=`find $BACKUPDIR/incr/$BEFORE_NEXT_FULL_INCR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1 | tail -1`
  echo "$BACKUPDIR/incr/$FULL/$LATEST_FULL_INCR"
else
  echo "$BACKUPDIR/full/$FULL"
fi
