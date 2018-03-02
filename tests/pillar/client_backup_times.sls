xtrabackup:
  client:
    enabled: true
    full_backups_to_keep: 3
    incr_before_full: 3
    backup_dir: /var/backups/mysql/xtrabackup
    backup_times:
      dayOfWeek: 0
#     month: *
#     dayOfMonth: *
      hour: 4
      minute: 52
    compression: true
    compression_threads: 2
    database:
      user: user
      password: password
    target:
      host: host01
    qpress:
      source: tar
      name: url