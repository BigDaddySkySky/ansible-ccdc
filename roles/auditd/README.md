# auditd

Purpose:
- Enable auditd-based host monitoring for competition environments
- Detect file changes, privilege escalation, and authentication activity

Used by:
- `critical-path` playbook

Changes:
- Installs auditd packages
- Deploys audit rules and configuration
- Enables and starts auditd service
- Optionally sends alerts via Discord

Key Inputs (vars):
- auditd_enabled
- auditd_monitored_files
- auditd_monitor_critical_dirs
- auditd_enable_discord_alerts
- auditd_discord_webhook

Notes:
- Generates high log volume; ensure disk space in `/var/log`
- Does not forward logs to SIEM (handled separately)
- Do not disable ICMP or SSH before deployment
