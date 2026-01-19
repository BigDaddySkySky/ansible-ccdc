# Scripts (Operator Tools)

Only two scripts are intended for competition use:

- `bootstrap.sh` — prepares the control node (venv + Ansible + collections + vault file check)
- `preflight.sh` — read-only checks (syntax, inventory parsing, vault file presence)

No other scripts in this directory should modify repo files or print secrets.
