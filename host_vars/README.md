# Host Vars Guide

Purpose
- Per-host secrets and overrides (passwords, unique settings) stored safely for automation.

When to Use
- Update vault files after password rotation or when White Team issues new credentials.

Files
- `host_vars/<hostname>/vault.yml`: encrypted per-host passwords/tokens.
- Additional host-specific overrides can be added alongside vaults if needed.

Dependencies
- `ansible-vault edit host_vars/<hostname>/vault.yml` with `~/.vault_pass` present.
- Hostnames must match inventory; do not rename hosts.

Validation
- `ansible-vault view host_vars/<host>/vault.yml` to confirm presence.
- `ansible <host> -m ping` after updates to ensure become/SSH still work.

White Team Visibility
- Only credential storage; no configuration changes occur here.

Inject Impact
- Rapid credential updates keep automation running while teammates handle inject deliverables.
