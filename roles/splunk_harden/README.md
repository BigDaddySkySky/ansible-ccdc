# splunk_harden

Purpose:
- Apply baseline hardening to the Splunk server

Used by:
- `critical-path` playbook

Changes:
- Hardens Splunk configuration files
- Applies secure defaults for services and authentication
- Restarts Splunk when required

Key Inputs (vars):
- splunk_enable_ssl
- splunk_disable_remote_login

Notes:
- Assumes Splunk is installed and configured
- Does not manage dashboards or forwarders
