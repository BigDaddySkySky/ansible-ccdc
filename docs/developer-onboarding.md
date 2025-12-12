# Developer Onboarding

## Required Tools
- Python 3.11+
- Ansible
- pre-commit
- GitHub Actions (CI) awareness

## Install Dependencies
```bash
python -m pip install --upgrade pip
pip install ansible ansible-lint yamllint pre-commit
ansible-galaxy collection install -r requirements.yml
```

## Run CI Locally
```bash
./scripts/ci.sh
```

## Run pre-commit Hooks
```bash
pre-commit install
pre-commit run --all-files
```

## Run the Hardening Chain Safely
1. Ensure vault password file exists (`~/.vault_pass`).
2. Validate environment: `ansible-playbook playbooks/10-validate-env.yml`.
3. Rotate passwords: `ansible-playbook playbooks/20-rotate-passwords.yml`.
4. Apply hardening: `ansible-playbook playbooks/30-hardening-main.yml --limit <hosts>`.
5. Validate scored services manually (22/80/443/25/110/21/53, ICMP).

## Vaults and Inventories
- Vaults live in `group_vars/all/vault.yml` and `host_vars/<host>/vault.yml`.
- Inventories: `inventory/staging.ini` (lab) and `inventory/production.ini` (competition). Do not commit real IPs.

## Adding New Hosts or Roles
- Add hosts to inventory and create `host_vars/<host>/vault.yml` with credentials.
- Add roles under `roles/` with defaults/handlers/meta; document with README.

## Common Pitfalls
- Lockout risk: run key deployment and password rotation before ssh_hardening/firewall.
- Missing collections: run `ansible-galaxy collection install -r requirements.yml`.
- Palo Alto tasks require `paloaltonetworks.panos` and HTTPAPI connection vars.
- Splunk tasks assume `/opt/splunk` and firewalld; adjust vars if different.
