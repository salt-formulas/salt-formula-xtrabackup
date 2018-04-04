xtrabackup:
  server:
    enabled: true
    full_backups_to_keep: 3
    incr_before_full: 3
    backup_dir: /srv/backup
    backup_times:
      day_of_week: 0
#     month: *
#     day_of_month: *
      hour: 4
      minute: 52
    key:
      xtrabackup_pub_key:
        enabled: true
        key: key