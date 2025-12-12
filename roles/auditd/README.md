# Role: auditd

Purpose
- Deploy auditd rules for file integrity, auth, and privilege escalation monitoring with optional Discord alerts and evidence collection, without changing network settings.

When to Run
- After firewall hardening in the main stack; included in `playbooks/30-hardening-main.yml`.

Variables Required
- Toggles: `auditd_enabled`, `auditd_monitor_critical_dirs`, `auditd_monitor_file_deletion`.
- Lists: `auditd_monitored_files`, `auditd_critical_directories`.
- Alerts: `auditd_enable_discord_alerts`, `auditd_discord_webhook`.
- Evidence: `auditd_enable_evidence_collection`, `auditd_evidence_dir`.
- Uses vault values for webhooks/credentials; network map only for context (no IP changes).

Dependencies
- Packages: auditd/audispd-plugins (Debian) or audit/audit-libs (RedHat).
- Collections: `ansible.posix`, `community.general`.
- Sudo access on hosts.

Run Steps
1) Ensure SSH/sudo working (run `playbooks/10-validate-env.yml`).
2) `ansible-playbook playbooks/30-hardening-main.yml --tags auditd` (or full stack).

Validation (Scoring-Aligned)
- Service: `systemctl status auditd` active.
- Rules: `auditctl -l | wc -l` ~100+.
- Tests: `sudo ls /root` then `ausearch -k sudo_execution`; `touch /etc/test` then `ausearch -k file_integrity`.
- Scored services: verify 22/80/443/25/110/21/53 and ICMP unaffected (auditd is passive).

White Team Visibility
- Read-only monitoring; no firewall/IP/hostname changes; optional outbound Discord notifications summarize status.

Inject Impact
- Centralized evidence/logging reduces manual artifact collection for inject responses and incident reports.
