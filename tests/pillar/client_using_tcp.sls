xtrabackup:
  client:
    enabled: true
    full_backups_to_keep: 3
    hours_before_full: 48
    hours_before_incr: 12
    compression: true
    compression_threads: 2
    throttle: 20
    database:
      user: user
      password: password
      host: localhost
      port: 3306
    target:
      host: host01
    qpress:
      source: tar
      name: url
