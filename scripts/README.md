# Scripts

Operator helper scripts used during competition.

Only the scripts listed below are intended for use.

---

## Scripts

- `bootstrap.sh`  
  Prepares the control node (virtual environment, Ansible, required collections).

- `preflight.sh`  
  Read-only checks (syntax validation, inventory parsing, vault file presence).

---

## Notes

- Scripts must not modify repository contents
- Scripts must not print secrets or decrypted vault values
- All system changes are performed via Ansible playbooks
