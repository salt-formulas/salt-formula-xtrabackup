{%- from "xtrabackup/map.jinja" import server with context %}
#!/bin/sh

# The purpose of this script is to clean up unnecesary backups on a backup storage node (on xtrabackup server node)

BACKUPDIR={{ server.backup_dir }} # Backups base directory
FULLBACKUPDIR=$BACKUPDIR/full # Full backups directory
INCRBACKUPDIR=$BACKUPDIR/incr # Incremental backups directory
KEEP={{ server.full_backups_to_keep }} # Number of full backups (and its incrementals) to keep
{%- if server.backup_times is defined %}
INCRBEFOREFULL={{ server.incr_before_full }}
KEEPINCR=$(( $INCRBEFOREFULL * KEEP ))
{%- else %}
HOURSFULLBACKUPLIFE={{ server.hours_before_full }} # Lifetime of the latest full backup in hours
FULLBACKUPLIFE=$(( $HOURSFULLBACKUPLIFE * 60 * 60 ))
{%- endif %}

# Cleanup
{%- if server.backup_times is not defined %}
echo "Cleanup. Keeping only $KEEP full backups and its incrementals."
AGE=$(($FULLBACKUPLIFE * $KEEP / 60))
find $FULLBACKUPDIR -maxdepth 1 -type d -mmin +$AGE -execdir echo "removing: "$FULLBACKUPDIR/{} \; -execdir rm -rf $FULLBACKUPDIR/{} \; -execdir echo "removing: "$INCRBACKUPDIR/{} \; -execdir rm -rf $INCRBACKUPDIR/{} \;

echo
echo "completed: `date`"
exit 0
{%- else %}
echo "Cleanup. Keeping only $KEEP full backups and its incrementals."
NUMBER_OF_FULL=$(( `find $FULLBACKUPDIR -maxdepth 1 -type d -print| wc -l` - 1))
NUMBER_OF_INCR=$(( `find $INCRBACKUPDIR -maxdepth 2 -type d -print| wc -l` - 1))
FULL_TO_DELETE=$(( $NUMBER_OF_FULL - $KEEP ))
INCR_TO_DELETE=$(( $NUMBER_OF_INCR - $KEEPINCR ))
echo "Found $NUMBER_OF_FULL full backups and $KEEP should be kept. Thus $FULL_TO_DELETE will be deleted"
echo "Found $NUMBER_OF_INCR full backups and $KEEPINCR should be kept. Thus $INCR_TO_DELETE will be deleted"
if [ $FULL_TO_DELETE -gt 0 ] ; then
cd $FULLBACKUPDIR
ls -t | tail -n -$FULL_TO_DELETE | xargs -d '\n' rm -rf
else
echo "There are less full backups than required, not deleting anything."
fi
if [ $INCR_TO_DELETE -gt 0 ] ; then
cd $INCRBACKUPDIR
ls -t | tail -n -$INCR_TO_DELETE | xargs -d '\n' rm -rf
else
echo "There are less incremental backups than required, not deleting anything."
fi
{%- endif %}