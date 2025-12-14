# Practice Range Inventory

Purpose
- Single inventory for the Cyber Teams practice range (10.250.x.x) covering Linux/Unix servers, Windows boxes, security tools, and firewalls.
- Acts as the template for future competition inventories; keep hostnames stable to match `host_vars/*/vault.yml` and playbook limits.

File
- `range.ini`: canonical practice inventory with inline group vars for default credentials/become behavior; commented hosts mark optional lab systems (Splunk, VyOS).

Layout (range.ini)
- Linux/Unix: `ubuntu` (10.250.20.20), `oracle_linux` (10.250.20.30), `free_bsd` (10.250.20.10).
- Security tools: `kali` (10.250.40.100), `wazu` (10.250.40.110), `sec_onion` (10.250.40.120); `attack_tools` and `ids_tools` point here; `security_stack` is the IDS child group.
- Windows: `win_19_web` (10.250.30.15), `win_22_dns` (10.250.30.25), `win_10` (10.250.30.35).
- Network: `pafw` (10.250.20.254), `ftd` (10.250.30.254); grouped under `firewalls`; VyOS placeholder is commented.
- Group vars in-file: Linux/security/attack tools use `vault_default_password` with sudo enabled; Unix (FreeBSD) is root-only with `ansible_become=false`.

Usage
- Point Ansible at the range: `ansible-inventory -i inventory/range.ini --graph` then `ansible all -i inventory/range.ini -m ping --limit linux_servers`.
- Override the default inventory in `ansible.cfg` by passing `-i inventory/range.ini` or exporting `ANSIBLE_INVENTORY=inventory/range.ini`.
- When adding hosts, reuse existing groups so limits (`--limit servers`, `--limit firewalls`) stay valid and create matching `host_vars/<host>/vault.yml` entries.
- For new competitions, copy `range.ini` as a starting point and swap IPs without changing hostnames/group names.

Validation
- `ansible-inventory -i inventory/range.ini --graph`
- `ansible-playbook -i inventory/range.ini playbooks/01-connectivity-check.yml`
