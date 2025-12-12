# Competition-Day Workflow

## Overview (Order of Operations)
1) Preflight: `firewall_preflight` (read-only).
2) Credentials: key bootstrap (if needed) and password rotation.
3) Hardening chain: common_preflight → ssh_hardening → firewall → auditd → common_validation.
4) Splunk: splunk_install (if needed) → splunk_configure → splunk_harden → deploy forwarders.
5) Palo Alto: configure NAT/security.
6) Validation: scored services + SSH.
7) Rollback (if needed): firewall_rollback.
8) CI check for last-minute changes.

## Detailed Steps
### 1) Firewall Preflight (optional but recommended)
```bash
ansible-playbook -i inventory/production.ini -t firewall_preflight --check
```
- Gather backend, default zone, open ports, forwarding state. No changes.

### 2) Credentials
- Ensure `~/.vault_pass` present; inventories updated.
- If defaults still in use: `ansible-playbook playbooks/00-bootstrap-keys.yml --limit new_vms`.
- Rotate passwords: `ansible-playbook playbooks/20-rotate-passwords.yml`.

### 3) Hardening Chain
```bash
ansible-playbook playbooks/30-hardening-main.yml --limit linux_servers
```
Order inside: common_preflight → ssh_hardening → firewall → auditd → common_validation. Use tags to phase if needed (`--tags ssh`, then `--tags firewall`, then `--tags auditd`).

### 4) Splunk
- If Splunk not installed: include `splunk_install` (package URL + vault_splunk_admin_password).
- Configure: `splunk_configure` to seed admin password and open UI port.
- Harden: `ansible-playbook playbooks/40-harden-splunk.yml`.
- Forwarders: `ansible-playbook playbooks/50-deploy-forwarders.yml --limit linux_servers:!splunk_vm`.

### 5) Palo Alto
```bash
ansible-playbook playbooks/32-configure-palo.yml
```
- Ensure `vault_palo_admin_user/password` and network IPs are set. Verifies NAT/security for scored services and ICMP.

### 6) Validation
- SSH: `ansible-playbook playbooks/01-connectivity-check.yml`.
- Scored ports: curl/telnet/dig for 22/80/443/25/110/21/53 + ICMP.
- Splunk: confirm 8000/8089/9997 reachable if used.

### 7) Rollback (panic)
```bash
ansible-playbook -i inventory/production.ini -l <hosts> -e "firewall_rb_reset_sysctl=true" roles/firewall_rollback
```
- Resets ufw/firewalld to allow and reopens scored ports; re-enables forwarding if configured.

### 8) CI for last-minute changes
- Run locally: `./scripts/ci.sh` (ansible-lint, yamllint, syntax-check, inventory validate).

## Notes
- Keep snapshots before firewall/ssh changes.
- Ensure collections installed: `ansible-galaxy collection install -r requirements.yml`.
- Palo Alto automation needs device reachability over HTTPS and proper HTTPAPI vars.
- Validate after each major step; stop if SSH or scored ports drop.
