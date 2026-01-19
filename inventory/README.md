# Inventory (Competition Day)

This directory defines **Ansible inventory only**.

**Important:** Inventory names here are *Ansible aliases*. They do **not** change system hostnames or IPs on the target systems.

---

## Files

- `staging.ini`  
  Practice / validation inventory (VMware or lab). Not used on competition day unless you intentionally choose to.

- `production.ini`  
  Competition inventory. Fill this file **day-of** using the team packet and White Team guidance.

---

## Competition Day Workflow

1. Open `inventory/production.ini`
2. Fill in `ansible_host=` values for each system you plan to manage
3. Validate reachability before making changes

Example:
```bash
ansible -i inventory/production.ini all --list-hosts
ansible -i inventory/production.ini all -m ping
```

Then proceed with the runbook:

```bash
ansible-playbook -i inventory/production.ini playbooks/02-validate-environment.yml
ansible-playbook -i inventory/production.ini playbooks/04-critical-path.yml
```

---

## Naming Standard (Required)

Use short, competition-real aliases:

* `ecom`
* `webmail`
* `splunk`
* `wkst`

If you add additional hosts, name them by **service role**, not by OS or “vm” naming.

---

## Safety Rules

Do not:

* Commit real competition IPs to GitHub
* Change inventory aliases mid-competition unless coordinated
* Assume any derived “team subnet math” is authoritative (prefer the team packet)

If White Team guidance conflicts with this repo, follow White Team.