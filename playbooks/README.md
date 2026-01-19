# Playbooks (Competition Runbook)

This directory contains the **competition execution path**. Playbooks are numbered in the intended order of use.

**Rule:** Do not run playbooks on hosts you cannot recover manually.

---

## Required Order (Competition)

### 00 — Bootstrap Keys (SSH survivability)
**File:** `00-bootstrap-keys.yml`  
Use when: you need to ensure your control node can access hosts via SSH reliably.

Notes:
- This may prompt for passwords (`-k`) depending on the environment.
- Run this before any hardening that could affect SSH access.

Example:
```bash
ansible-playbook playbooks/00-bootstrap-keys.yml -k
```

---

### 01 — Discover Hosts (optional)

**File:** `01-discover-hosts.yml`
Use when: you have partial info and need to build a first-pass view of what responds.

---

### 02 — Validate Environment (mandatory before changes)

**File:** `02-validate-environment.yml`
Use when: you want a clear view of what is reachable and safe to modify.

Run this before the critical path.

---

### 03 — Rotate Passwords (high risk)

**File:** `03-rotate-passwords.yml`
Use when: you are ready to rotate credentials and can verify access afterward.

Do not run blindly. Credential rotation can break scoring services if not coordinated.

---

### 04 — Critical Path (first ~20 minutes)

**File:** `04-critical-path.yml`
This is the primary competition playbook.

Use when:

* You have validated reachability
* You want to apply safe, competition-tested baseline controls

---

## Splunk Playbooks (Phase 2)

These are important, but are intentionally not part of the initial “first 20 minutes” push unless telemetry is a required objective at drop flag.

* `00-install-splunk.yml` (only if Splunk server must be installed)
* `04-configure-splunk.yml`
* `05-harden-splunk.yml`
* `06-install-forwarders.yml`

---

## Safe Defaults

If you are uncertain, run in this order:

1. `00-bootstrap-keys.yml -k`
2. `02-validate-environment.yml`
3. `04-critical-path.yml`

---

## Stop Conditions

Stop automation if:

* SSH access is lost to a critical host
* A scored service drops
* White Team guidance conflicts with automation behavior

```

**Explicit instruction:** add that file and commit it.

---

## ✅ After you commit those two files
Run this quick sanity check (no secrets printed):

```bash
ansible-playbook -i inventory/staging.ini playbooks/04-critical-path.yml --syntax-check
```

If it passes, you’re good.
