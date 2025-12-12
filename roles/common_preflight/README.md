# Role: common_preflight

Purpose
- Minimal pre-checks on each host before hardening to avoid lockouts.

When to Run
- First role in any hardening play; already invoked by `30-hardening-main.yml`.

Variables Required
- None beyond inventory connection vars; uses `ansible_user`/`ansible_become`.

Dependencies
- Ansible facts; sudo privilege.


Validation
- Ensures Ansible 2.15+, supported OS families (Debian/RedHat), SSH ping works, sudo returns root.

White Team Visibility
- Read-only checks plus a `whoami` with sudo; no config changes.

Inject Impact
- Quick failure signals free responders to handle injects while fixing access.
