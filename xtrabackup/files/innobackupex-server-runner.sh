{%- from "xtrabackup/map.jinja" import server with context %}
#!/bin/sh

# The purpose of this script is to clean up unnecesary backups on a backup storage node (on xtrabackup server node)

BACKUPDIR={{ server.backup_dir }} # Backups base directory
FULLBACKUPDIR=$BACKUPDIR/full # Full backups directory
INCRBACKUPDIR=$BACKUPDIR/incr # Incremental backups directory
HOURSFULLBACKUPLIFE={{ server.hours_before_full }} # Lifetime of the latest full backup in seconds
FULLBACKUPLIFE=$(( $HOURSFULLBACKUPLIFE * 60 * 60 ))
KEEP={{ server.full_backups_to_keep }} # Number of full backups (and its incrementals) to keep

# Cleanup
echo "Cleanup. Keeping only $KEEP full backups and its incrementals."
AGE=$(($FULLBACKUPLIFE * $KEEP / 60))
find $FULLBACKUPDIR -maxdepth 1 -type d -mmin +$AGE -execdir echo "removing: "$FULLBACKUPDIR/{} \; -execdir rm -rf $FULLBACKUPDIR/{} \; -execdir echo "removing: "$INCRBACKUPDIR/{} \; -execdir rm -rf $INCRBACKUPDIR/{} \;
