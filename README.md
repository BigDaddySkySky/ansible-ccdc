# MWCCDC Ansible Automation (Competition Repository)

**Primary objective:** Secure reachable Linux services in the first ~20 minutes
**Secondary objective:** Do no harm to scoring, access, or availability

This repository contains **competition-day automation only**.
It is intentionally strict, minimal, and opinionated.

---

## Operator Assumptions (Read First)

This repo assumes:

* You are operating after drop flag
* You have valid credentials (SSH + sudo) for at least one Linux host
* You are running from a Linux control node (Ubuntu preferred)
* You are prioritizing service uptime and scoring stability

If any of the above are false, **do not proceed blindly**.

---

## Design Principles

1. **Connectivity First**
   No host is modified until SSH connectivity is verified.

2. **Graceful Degradation**
   If a host is unreachable, automation continues on others.

3. **Competition Safety**
   No hostname changes, no IP changes, no service removals unless explicitly defined.

4. **Operator Clarity**
   Every playbook is numbered in execution order and scoped deliberately.

5. **No Heroics**
   Automation favors safe defaults over aggressive hardening.

---

## Competition-Day Quick Start

### Step 1: Bootstrap the control environment

Run once on the control node:

```bash
./scripts/bootstrap.sh
```

This prepares Python, Ansible, required collections, and validates vault configuration.

---

### Step 2: Establish and preserve access

```bash
ansible-playbook playbooks/00-bootstrap-keys.yml -k
```

Ensure reliable SSH access before any hardening occurs.

Run a second time with, limited to Splunk, to handle default password variations:
```bash
ansible-playbook playbooks/00-bootstrap-keys.yml -l splunk -k
```

---

### Step 3: Rotate credentials (intentional, not blind)

```bash
ansible-playbook playbooks/01-rotate-passwords.yml
```

Only run once access is verified and recovery is possible.

---

### Step 4: Run the critical path (first ~20 minutes)

```bash
ansible-playbook playbooks/02-critical-path.yml
```

Applies competition-tested baseline controls to reachable hosts.

---

### Step 5: Configure telemetry (after stabilization)

```bash
ansible-playbook playbooks/03-configure-splunk.yml
ansible-playbook playbooks/04-install-forwarders.yml
```

Enable centralized logging after core services are stable.

---

## Repository Structure (Operator View)

```text
ansible-ccdc-v2/
├── scripts/          Control-node helpers
├── inventory/        Competition inventory
├── group_vars/       Group-level configuration
├── host_vars/        Host-specific overrides
├── playbooks/        Numbered execution order
└── roles/            Modular hardening components
```

---

## Secrets and Vault Handling

Sensitive values (passwords, service credentials, webhooks) are stored in **Ansible Vault**.

* Vault passwords are never stored in this repository
* Vault contents are encrypted and guarded with `no_log: true`
* Vault access is provided out-of-band via `~/.vault_pass`

Refer to `group_vars/VAULT_CONTENTS.md` and `host_vars/VAULT_CONTENTS.md` for documented intent.

---

## What NOT to Do During Competition

Do not:

* Rename hosts or change IP addresses
* Run unnumbered or experimental playbooks
* Modify firewall rules unless explicitly instructed
* Rotate passwords without validation
* Run automation on hosts you cannot recover manually

If unsure, **pause and reassess**.

---

## When to Stop

Stop automation immediately if:

* SSH access is lost to a critical host
* A scored service becomes unavailable
* White Team guidance conflicts with automation behavior

Manual intervention takes priority.

---

## Success Criteria

You are succeeding if:

* SSH access is preserved
* Services remain available
* Credentials are controlled
* Telemetry is flowing
* You can explain every change made

---

## Final Note

This repository exists to **buy time and reduce risk**, not to replace operator judgment.