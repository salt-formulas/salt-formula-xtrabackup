{%- from "xtrabackup/map.jinja" import server with context %}
{%- if server.enabled %}

xtrabackup_server_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

{%- set parent_backup_dir = salt['file.dirname'](server.backup_dir) %}

{{  parent_backup_dir  }}:
  file.directory:
  - mode: 755
  - user: root
  - group: root
  - makedirs: true
  - require:
    - pkg: xtrabackup_server_packages

xtrabackup_user:
  user.present:
  - name: xtrabackup
  - system: true
  - home: {{ server.backup_dir }}
  - groups:
    - xtrabackup

xtrabackup_group:
  group.present:
  - name: xtrabackup
  - system: true
  - require_in:
    - user: xtrabackup_user

{{ server.backup_dir }}/full:
  file.directory:
  - mode: 755
  - user: xtrabackup
  - group: xtrabackup
  - makedirs: true
  - require:
    - user: xtrabackup_user
    - pkg: xtrabackup_server_packages

{{ server.backup_dir }}/incr:
  file.directory:
  - mode: 755
  - user: xtrabackup
  - group: xtrabackup
  - makedirs: true
  - require:
    - user: xtrabackup_user
    - pkg: xtrabackup_server_packages

{{ server.backup_dir }}/.ssh:
  file.directory:
  - mode: 700
  - user: xtrabackup
  - group: xtrabackup
  - require:
    - user: xtrabackup_user

{{ server.backup_dir }}/.ssh/authorized_keys:
  file.managed:
  - user: xtrabackup
  - group: xtrabackup
  - template: jinja
  - source: salt://xtrabackup/files/authorized_keys
  - require:
    - file: {{ server.backup_dir }}/full
    - file: {{ server.backup_dir }}/incr
    - file: {{ server.backup_dir }}/.ssh

xtrabackup_server_script:
  file.managed:
  - name: /usr/local/bin/innobackupex-runner.sh
  - source: salt://xtrabackup/files/innobackupex-server-runner.sh
  - template: jinja
  - mode: 655
  - require:
    - pkg: xtrabackup_server_packages

{%- if server.cron %}

xtrabackup_server_cron:
  cron.present:
  - name: /usr/local/bin/innobackupex-runner.sh
  - user: xtrabackup
  - minute: 0
  - hour: 2
  - require:
    - file: xtrabackup_server_script

{%- else %}

xtrabackup_server_cron:
  cron.absent:
  - name: /usr/local/bin/innobackupex-runner.sh
  - user: xtrabackup

{%- endif %}

xtrabackup_server_call_restore_script:
  file.managed:
  - name: /usr/local/bin/innobackupex-restore-call.sh
  - source: salt://xtrabackup/files/innobackupex-server-restore-call.sh
  - template: jinja
  - mode: 655
  - require:
    - pkg: xtrabackup_server_packages

{%- endif %}
