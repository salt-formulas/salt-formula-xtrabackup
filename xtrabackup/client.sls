{%- from "xtrabackup/map.jinja" import client with context %}
{%- if client.enabled %}

xtrabackup_client_packages:
  pkg.installed:
  - names: {{ client.pkgs }}

xtrabackup_client_runner_script:
  file.managed:
  - name: /usr/local/bin/innobackupex-runner.sh
  - source: salt://xtrabackup/files/innobackupex-client-runner.sh
  - template: jinja
  - mode: 655
  - require:
    - pkg: xtrabackup_client_packages

xtrabackups_full_dir:
  file.directory:
  - name: {{ client.backup_dir }}/full
  - user: root
  - group: root
  - makedirs: true

xtrabackups_incr_dir:
  file.directory:
  - name: {{ client.backup_dir }}/incr
  - user: root
  - group: root
  - makedirs: true

{%- if client.cron %}

xtrabackup_client_runner_cron:
  cron.present:
  - name: /usr/local/bin/innobackupex-runner.sh
  - user: root
{%- if client.backup_times is defined %}
{%- if client.backup_times.day_of_week is defined %}
  - dayweek: {{ client.backup_times.day_of_week }}
{%- endif -%}
{%- if client.backup_times.month is defined %}
  - month: {{ client.backup_times.month }}
{%- endif %}
{%- if client.backup_times.day_of_month is defined %}
  - daymonth: {{ client.backup_times.day_of_month }}
{%- endif %}
{%- if client.backup_times.hour is defined %}
  - hour: {{ client.backup_times.hour }}
{%- endif %}
{%- if client.backup_times.minute is defined %}
  - minute: {{ client.backup_times.minute }}
{%- endif %}
{%- elif client.hours_before_incr is defined %}
  - minute: 0
{%- if client.hours_before_incr <= 23 and client.hours_before_incr > 1 %}
  - hour: '*/{{ client.hours_before_incr }}'
{%- elif not client.hours_before_incr <= 1 %}
  - hour: 2
{%- endif %}
{%- else %}
  - hour: 2
{%- endif %}
  - require:
    - file: xtrabackup_client_runner_script

{%- else %}

xtrabackup_client_runner_cron:
  cron.absent:
  - name: /usr/local/bin/innobackupex-runner.sh
  - user: root

{%- endif %}

{%- if client.restore_full_latest is defined %}

xtrabackup_client_restore_script:
  file.managed:
  - name: /usr/local/bin/innobackupex-restore.sh
  - source: salt://xtrabackup/files/innobackupex-client-restore.sh
  - template: jinja
  - mode: 655
  - require:
    - pkg: xtrabackup_client_packages

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
  - unless: "[ -e {{ client.backup_dir }}/dbrestored ]"
  - require:
    - file: xtrabackup_client_call_restore_script

{%- endif %}


{%- endif %}
