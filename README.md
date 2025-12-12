[![Lint](https://github.com/smoyers/ansible-ccdc/actions/workflows/lint.yml/badge.svg)](https://github.com/smoyers/ansible-ccdc/actions/workflows/lint.yml)

# CCDC Ansible Automation (Blue Team Runbook)

Purpose
- End-to-end automation to secure MWCCDC Linux assets in the first 20 minutes without violating rules (no IP/hostname changes, no blocking public IP ranges).

When to Use
- Competition day after initial SSH key drop; use as the master reference for which playbooks to run and in what order.

Variables Required
- `group_vars/all/competition.yml`: network/IP map (do not change day-of unless White Team says so).
- `group_vars/all/vault.yml` + `host_vars/*/vault.yml`: credentials, Discord webhook, per-host passwords.
- `group_vars/linux_servers/connection.yml`: SSH user/become settings (flip to vault_host_password after rotation).

Dependencies
- Ansible 2.15+, collections `community.general`, `ansible.posix`, `paloaltonetworks.panos`.
- SSH keys present on targets; vault password file at `~/.vault_pass`.

Execution (first 20 minutes)
1) `./scripts/bootstrap.sh` -> `source .venv/bin/activate`
2) Validate: `ansible-playbook playbooks/10-validate-env.yml`
3) Rotate passwords: `ansible-playbook playbooks/20-rotate-passwords.yml`
4) Hardening stack: `ansible-playbook playbooks/30-hardening-main.yml --limit reachable_hosts`
5) Splunk: `ansible-playbook playbooks/40-harden-splunk.yml` then `playbooks/50-deploy-forwarders.yml`
6) Palo Alto (if reachable): `ansible-playbook playbooks/32-configure-palo.yml`

Validation (scoring-focused)
- HTTP/HTTPS (80/443), SMTP (25), POP3 (110), FTP (21), DNS (53), SSH (22): run `./scripts/test-sprint.sh` or `curl/telnet/dig` per host; confirm ICMP responds.
- Check `ansible-playbook playbooks/01-connectivity-check.yml` success on all scored hosts.

White Team Visibility
- Reports show SSH-only changes, firewall rules limited to scored services, no IP/hostname changes, Discord notifications optional.
- Palo Alto changes are NAT/security rules only; no interface renumbering.

Inject Impact
- Automation keeps scored services online so teammates can answer injects; password rotation and logging reduce incident response load.

Rollback/Notes
- Use hypervisor snapshots before major playbooks.
- `playbooks/99-nuke-firewall.yml` is the panic button if scoring drops due to firewall.
