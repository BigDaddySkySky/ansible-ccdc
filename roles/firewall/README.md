# Role: firewall

Purpose
- Configure host-based firewall (ufw/firewalld) to allow only scored services while keeping SSH and ICMP reachable.

When to Run
- After SSH hardening; before auditd; included in `playbooks/30-hardening-main.yml`.

Variables Required
- Backend: `firewall_backend` (auto: ufw on Debian, firewalld on RedHat).
- Services: `firewall_scored_services` (defaults: 22,80,443,25,110,21,53 + ICMP), optional `firewall_additional_services` per host.
- Access lists: `firewall_scoring_ips`, `firewall_whiteteam_ips`.
- Controls: `firewall_enable_rate_limiting`, `firewall_ssh_rate_limit`, logging toggles.

Dependencies
- Collections: `community.general`, `ansible.posix`.
- Packages: ufw or firewalld present; sysctl for SYN protection.

Run Steps
1) Ensure SSH keys and sudo work.
2) Snapshot VMs if possible.
3) `ansible-playbook playbooks/30-hardening-main.yml --tags firewall` (or full stack).

Validation (Scoring-Aligned)
- Status: `ufw status` or `firewall-cmd --state`.
- Ports reachable: SSH 22; HTTP/HTTPS 80/443; SMTP 25; POP3 110; FTP 21; DNS 53; ICMP.
- Logs: `/var/log/ufw.log` or `journalctl -u firewalld -n 50`.

White Team Visibility
- Rules limited to host firewall; no IP/hostname changes; public ranges not blocked beyond non-scored ports; ICMP allowed for scoring.

Inject Impact
- Automates rule enforcement so responders can focus on inject tasks; panic rollback available via `playbooks/99-nuke-firewall.yml`.
