xtrabackup:
  client:
    enabled: true
    full_backups_to_keep: 3
    hours_before_full: 48
    hours_before_incr: 12
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