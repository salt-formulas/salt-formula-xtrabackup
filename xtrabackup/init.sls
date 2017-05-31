{%- if pillar.xtrabackup is defined %}
include:
{%- if pillar.xtrabackup.client is defined %}
- xtrabackup.client
{%- endif %}
{%- if pillar.xtrabackup.server is defined %}
- xtrabackup.server
{%- endif %}
{%- endif %}
