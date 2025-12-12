# Inventory Guide

Purpose
- Keep staging lab and competition inventories separated and competition-legal.

When to Use
- Edit `production.ini` on competition morning with real IPs; use `staging.ini` for VMware lab testing.

Variables Required
- Host IPs per scored host; group memberships (`linux_servers`, `palo_firewalls`, `critical_services`).
- `all:vars` flags: `staging_environment`, `team_number`, `competition_name`.

Dependencies
- Vault secrets for host passwords; SSH keys already deployed.

Steps
1) Copy `inventory/staging.ini` to `inventory/production.ini`.
2) Fill real IPs; do NOT change hostnames or subnets from White Team packet.
3) Remove `ansible_password` entries once keys + vault passwords are active.
4) Use `--limit` with groups (`critical_services`, `palo_firewalls`) during runs.

Validation
- `ansible-inventory -i inventory/production.ini --graph`.
- `ansible-playbook -i inventory/production.ini playbooks/01-connectivity-check.yml`.

White Team Visibility
- Operates only on provided IPs; no topology changes.

Inject Impact
- Clean inventory enables fast targeting for inject-specific hosts without hitting the wrong box.
