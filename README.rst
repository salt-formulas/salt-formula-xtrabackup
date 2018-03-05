
===================
xtrabackup formula
===================

Xtrabackup allows you to backup and restore databases from full backups or full backups and its incrementals.


Sample pillars
==============

Backup client with ssh/rsync remote host

.. code-block:: yaml

    xtrabackup:
      client:
        enabled: true
        full_backups_to_keep: 3
        hours_before_full: 48
        hours_before_incr: 12
        database:
          user: username
          password: password
        target:
          host: cfg01

  .. note:: full_backups_to_keep param states how many backup will be stored locally on xtrabackup client.
            More options to relocate local backups can be done using salt-formula-backupninja.


Backup client with local backup only

.. code-block:: yaml

    xtrabackup:
      client:
        enabled: true
        full_backups_to_keep: 3
        hours_before_full: 48
        hours_before_incr: 12
        database:
          user: username
          password: password

  .. note:: full_backups_to_keep param states how many backup will be stored locally on xtrabackup client


Backup client with ssh/rsync to remote host with compression and non-default backup directory on server:

.. code-block:: yaml

    xtrabackup:
      client:
        enabled: true
        full_backups_to_keep: 3
        hours_before_full: 48
        hours_before_incr: 12
        compression: true
        compression_threads: 2
        database:
          user: username
          password: password
        target:
          host: cfg01
      server:
        enabled: false
        backup_dir: /srv/backup

  .. note:: More options to relocate local backups can be done using salt-formula-backupninja.

  .. note:: If the ``server`` section is ommited backups will be made to
  default location, same on both client and server side.


Backup client at exact times:

..code-block:: yaml

  xtrabackup:
    client:
      enabled: true
      full_backups_to_keep: 3
      incr_before_full: 3
      backup_dir: /var/backups/mysql/xtrabackup
      backup_times:
        dayOfWeek: 0
        hour: 4
        minute: 52
      compression: true
      compression_threads: 2
      database:
        user: user
        password: password
      target:
        host: host01

  .. note:: Parameters in ``backup_times`` section can be used to set up exact
  time the cron job should be executed. In this example, the backup job
  would be executed every Sunday at 4:52 AM. If any of the individual
  ``backup_times`` parameters is not defined, the defalut ``*`` value will be
  used. For example, if minute parameter is ``*``, it will run the backup every minute,
  which is ususally not desired.
  Available parameters are ``dayOfWeek``, ``dayOfMonth``, ``month``, ``hour`` and ``minute``.
  Please see the crontab reference for further info on how to set these parameters.

  .. note:: Please be aware that only ``backup_times`` section OR
  ``hours_before_full(incr)`` can be defined. If both are defined, The
  ``backup_times`` section will be peferred.

  .. note:: New parameter ``incr_before_full`` needs to be defined. This
  number sets number of incremental backups to be run, before a full backup
  is performed.


Backup server rsync and non-default backup directory:

.. code-block:: yaml

    xtrabackup:
      server:
        enabled: true
        hours_before_full: 48
        full_backups_to_keep: 5
        key:
          xtrabackup_pub_key:
            enabled: true
            key: key
        backup_dir: /srv/backup

  .. note:: hours_before_full param should have the same value as is stated on xtrabackup client

  .. note:: If the ``backup_dir`` argument is ommited backups will be made to
  default location, same on both client and server side.


Backup server without strict client restriction

.. code-block:: yaml

    xtrabackup:
      server:
        restrict_clients: false


Backup server at exact times:

..code-block:: yaml

  xtrabackup:
    server:
      enabled: true
      full_backups_to_keep: 3
      incr_before_full: 3
      backup_dir: /srv/backup
      backup_times:
        dayOfWeek: 0
        hour: 4
        minute: 52
      key:
        xtrabackup_pub_key:
          enabled: true
          key: key

  .. note:: Parameters in ``backup_times`` section can be used to set up exact
  time the cron job should be executed. In this example, the backup job
  would be executed every Sunday at 4:52 AM. If any of the individual
  ``backup_times`` parameters is not defined, the defalut ``*`` value will be
  used. For example, if minute parameter is ``*``, it will run the backup every minute,
  which is ususally not desired.
  Please see the crontab reference for further info on how to set these parameters.

  .. note:: Please be aware that only ``backup_times`` section OR
  ``hours_before_full(incr)`` can be defined. If both are defined, The
  ``backup_times`` section will be peferred.

  .. note:: New parameter ``incr_before_full`` needs to be defined. This
  number sets number of incremental backups to be run, before a full backup
  is performed.

Client restore from local backups:

.. code-block:: yaml

    xtrabackup:
      client:
        enabled: true
        full_backups_to_keep: 5
        hours_before_full: 48
        hours_before_incr: 12
        restore_full_latest: 1
        restore_from: local
        compression: true
        compressThreads: 2
        database:
          user: username
          password: password
        target:
          host: cfg01
        qpress:
          source: tar
          name: url

  .. note:: restore_full_latest param with a value of 1 means to restore db from the last full backup and its increments. 2 would mean to restore second latest full backup and its increments


Client restore from remote backups: 

.. code-block:: yaml

    xtrabackup:
      client:
        enabled: true
        full_backups_to_keep: 5
        hours_before_full: 48
        hours_before_incr: 12
        restore_full_latest: 1
        restore_from: remote
        compression: true
        compressThreads: 2
        database:
          user: username
          password: password
        target:
          host: cfg01
        qpress:
          source: tar
          name: url

  .. note:: restore_full_latest param with a value of 1 means to restore db from the last full backup and its increments. 2 would mean to restore second latest full backup and its increments


More information
================

* https://labs.riseup.net/code/projects/xtrabackup/wiki/Configuration
* http://www.debian-administration.org/articles/351
* http://duncanlock.net/blog/2013/08/27/comprehensive-linux-backups-with-etckeeper-xtrabackup/
* https://github.com/riseuplabs/puppet-xtrabackup
* http://www.ushills.co.uk/2008/02/backup-with-xtrabackup.html


Documentation and Bugs
======================

To learn how to install and update salt-formulas, consult the documentation
available online at:

    http://salt-formulas.readthedocs.io/

In the unfortunate event that bugs are discovered, they should be reported to
the appropriate issue tracker. Use Github issue tracker for specific salt
formula:

    https://github.com/salt-formulas/salt-formula-xtrabackup/issues

For feature requests, bug reports or blueprints affecting entire ecosystem,
use Launchpad salt-formulas project:

    https://launchpad.net/salt-formulas

You can also join salt-formulas-users team and subscribe to mailing list:

    https://launchpad.net/~salt-formulas-users

Developers wishing to work on the salt-formulas projects should always base
their work on master branch and submit pull request against specific formula.

    https://github.com/salt-formulas/salt-formula-xtrabackup

Any questions or feedback is always welcome so feel free to join our IRC
channel:

    #salt-formulas @ irc.freenode.net

