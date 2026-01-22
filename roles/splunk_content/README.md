# splunk_content

Purpose:
- Deploy Splunk UI content used by the team (dashboards, views)

Used by:
- `configure-splunk` playbook

Changes:
- Uploads Dashboard Studio / view JSON to Splunk via REST

Key Inputs (vars):
- vault_splunk_admin_password
- splunk_mgmt_port
- splunk_content_overwrite

Notes:
- Assumes Splunk is installed and reachable on the management API (8089)
- Content deployment is separate from Splunk hardening
