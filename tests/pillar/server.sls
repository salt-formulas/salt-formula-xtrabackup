xtrabackup:
  server:
    enabled: true
    hours_before_full: 48
    full_backups_to_keep: 5
    key:
      xtrabackup_pub_key:
        enabled: true
        key: pub_key