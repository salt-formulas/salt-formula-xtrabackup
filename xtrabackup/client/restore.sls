{%- from "xtrabackup/map.jinja" import client with context %}
{%- if client.enabled %}

{%- if client.restore_full_latest is defined %}

xtrabackup_client_restore_script:
  file.managed:
  - name: /usr/local/bin/innobackupex-restore.sh
  - source: salt://xtrabackup/files/innobackupex-client-restore.sh
  - template: jinja
  - mode: 655

xtrabackup_client_call_restore_script:
  file.managed:
  - name: /usr/local/bin/innobackupex-restore-call.sh
  - source: salt://xtrabackup/files/innobackupex-client-restore-call.sh
  - template: jinja
  - mode: 655
  - require:
    - file: xtrabackup_client_restore_script

xtrabackup_run_restore:
  cmd.run:
  - name: /usr/local/bin/innobackupex-restore-call.sh
  - user: root
  - unless: "[ -e {{ client.backup_dir }}/dbrestored ]"
  - require:
    - file: xtrabackup_client_call_restore_script

{%- endif %}

{%- endif %}
