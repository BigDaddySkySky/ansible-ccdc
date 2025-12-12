# Playbook Run Order (Competition)

Purpose
- Fast map of playbooks to actions and scoring services.

Timeline
- 00 Bootstrap keys: `00-bootstrap-keys.yml` (deploy SSH keys using default passwords to [new_vms]).
- 01 Connectivity: `01-connectivity-check.yml` (ping via SSH).
- 10 Validate: `10-validate-env.yml` (control node + host readiness).
- 11 Discover: `11-discover-hosts.yml` (read-only baseline of services/ports/users).
- 20 Rotate: `20-rotate-passwords.yml` (move from default creds to vault_host_password).
- 30 Harden: `30-hardening-main.yml` (common_preflight → ssh_hardening → firewall → auditd → common_validation + Discord notify).
- 32 Palo Alto: `32-configure-palo.yml` (NAT/security rules; no interface changes).
- 40 Splunk harden: `40-harden-splunk.yml` (hardening for Splunk app).
- 50 Forwarders: `50-deploy-forwarders.yml` (install UF on linux_servers except splunk_vm).
- 99 Panic: `99-nuke-firewall.yml` (disable host firewalls if locked out).

Variables Needed
- Vault passwords per host; network map `group_vars/all/competition.yml`; Palo creds for 32; Splunk admin password for 40/50.

Validation
- After each run, re-check scored ports: 22/80/443/25/110/21/53 and ICMP.
- `ansible-playbook playbooks/10-validate-env.yml` and `./scripts/test-sprint.sh` as smoke tests.

White Team Visibility
- Playbooks only touch allowed services; no IP/hostname changes; public ranges stay unblocked except non-scored ports.

Inject Impact
- Repeatable run order frees time for documentation and inject responses.
