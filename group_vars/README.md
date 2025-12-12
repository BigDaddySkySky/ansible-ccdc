# Group Vars Guide

Purpose
- Central store for shared settings (network map, defaults, vault pointers) aligned to competition packet.

When to Use
- Update only when White Team provides new ranges or credentials; never guess values.

Key Files
- `all/competition.yml`: CIDRs and public/private IP mapping for Linux/Windows segments and firewalls.
- `all/vault.yml`: encrypted global secrets (Discord webhook, default passwords).
- `linux_servers/connection.yml`: SSH user/become/SSH options; switch to vault_host_password after rotation.
- `linux_servers/packages.yml`, `services.yml`: extension points (currently empty).
- `palo_firewalls/connection.yml`: HTTPAPI settings for Palo Alto.

Dependencies
- Vault password file `~/.vault_pass`; use `ansible-vault` to edit.

Validation
- `ansible-vault view group_vars/all/competition.yml` (read-only check).
- `ansible all -m debug -a "var=ansible_user"` to confirm connection vars load.

White Team Visibility
- Variables mirror official packet values; no IP/hostname changes are made by automation.

Inject Impact
- Centralized variables avoid per-playbook edits so responders can focus on inject tasks.
