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

{%- for key_name, key in server.key.iteritems() %}

{%- if key.get('enabled', False) %}

{%- set clients = [] %}
{%- for node_name, node_grains in salt['mine.get']('*', 'grains.items').iteritems() %}
{%- if node_grains.get('xtrabackup') and node_grains.xtrabackup.get('client') %}
{%- set client = node_grains.xtrabackup.get("client") %}
{%- if client.get('addresses') and client.get('addresses', []) is iterable %}
{%- for address in client.addresses %}
{%- do clients.append(address|string) %}
{%- endfor %}
{%- endif %}
{%- endif %}
{%- endfor %}

xtrabackup_key_{{ key.key }}:
  ssh_auth.present:
  - user: xtrabackup
  - name: {{ key.key }}
  - options:
    - no-pty
{%- if clients %}
    - from="{{ clients|join(',') }}"
{%- endif %}
  - require:
    - file: {{ server.backup_dir }}/full
    - file: {{ server.backup_dir }}/incr

{%- endif %}

{%- endfor %}

xtrabackup_server_script:
  file.managed:
  - name: /usr/local/bin/innobackupex-runner.sh
  - source: salt://xtrabackup/files/innobackupex-server-runner.sh
  - template: jinja
  - mode: 655
  - require:
    - pkg: xtrabackup_server_packages

xtrabackup_server_cron:
  cron.present:
  - name: /usr/local/bin/innobackupex-runner.sh
  - user: xtrabackup
{%- if not server.cron %}
  - commented: True
{%- endif %}
  - minute: 0
  - hour: 2
  - require:
    - file: xtrabackup_server_script

xtrabackup_server_call_restore_script:
  file.managed:
  - name: /usr/local/bin/innobackupex-restore-call.sh
  - source: salt://xtrabackup/files/innobackupex-server-restore-call.sh
  - template: jinja
  - mode: 655
  - require:
    - pkg: xtrabackup_server_packages

{%- endif %}
