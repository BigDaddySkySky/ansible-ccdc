# Inventory

Inventories used to define `ansible_host` values.

---

## Files

* `staging.ini`  
  Lab / validation inventory.

* `production.ini`  
  Competition inventory.  
  May be prepared ahead of time and may contain real competition IP addresses.  
  Contains **no credentials** (secrets live in Ansible Vault).

---

## Standards

* Use service-based aliases (`ecom`, `webmail`, `splunk`, `wkst`)
* Aliases are identifiers only; they do not rename systems
* Credentials and privilege escalation are not handled in inventory  
  Refer to `group_vars/VAULT_CONTENTS.md` and `host_vars/VAULT_CONTENTS.md`
* Connection defaults are defined in `ansible.cfg`

---

## Competition Notes

* Assigned IPs and hostnames must not be changed unless directed by an inject
* If White Team guidance conflicts with this repo, follow White Team
