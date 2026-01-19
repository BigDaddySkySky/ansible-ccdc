# Variable Usage Rules (Competition Standard)

This document defines **where configuration values are allowed to live** during competition.

These rules exist to:

* Prevent conflicting values under time pressure
* Make secrets and configuration predictable to locate
* Reduce operator hesitation and mistakes

If a variable does not clearly belong somewhere, **stop and decide before proceeding**.

---

## 🎯 Objective

During competition, you should be able to answer instantly:

* *Where is this value defined?*
* *Is it global, group-specific, or host-specific?*
* *Is it safe to change right now?*

This hierarchy enforces that clarity.

---

## 📐 Variable Hierarchy (Mandatory)

### 1️⃣ `group_vars/all/` — Global Scope

Use **only** for values that apply to **every managed system**.

Examples:

* Global ports and constants
* Competition metadata (team number, environment flags)
* Secrets required by all hosts (e.g., shared alerting webhook)

Rules:

* Changes here affect **everything**
* Treat edits as **high-risk**
* Secrets in this scope **must be vaulted**

---

### 2️⃣ `group_vars/<group>/` — Group Scope

Use for values shared by a **logical class of systems**.

Examples:

* Package lists for Linux servers
* Service enable/disable flags by role
* Credentials shared within a service group

Rules:

* Changes affect **only that group**
* Prefer group scope over host scope whenever possible
* Secrets in this scope **must be vaulted**

---

### 3️⃣ `host_vars/<hostname>/` — Host Scope

Use **only** for values unique to a single system.

Examples:

* Per-host credentials
* Host-specific service configuration
* One-off exceptions that cannot be generalized

Rules:

* Highest specificity
* Lowest blast radius
* Avoid unless truly required

---

## 🚫 Prohibited Variable Usage

The following are **not allowed** during competition:

* Hardcoded values inside tasks
* Playbook-level variables (except short-lived control logic)
* Duplicating the same variable across multiple scopes
* “Temporary” overrides without documentation

If you need a temporary value, **define it properly or don’t proceed**.

---

## 📌 Common Placement Examples

| Configuration Item     | Correct Location                        |
| ---------------------- | --------------------------------------- |
| SSH port               | `group_vars/all/ports.yml`              |
| Team number            | `group_vars/all/competition.yml`        |
| Linux package list     | `group_vars/linux_servers/packages.yml` |
| Shared Discord webhook | `group_vars/all/vault.yml` (vaulted)    |
| Splunk admin password  | `host_vars/splunk/vault.yml` (vaulted)  |

---

## 🔐 Secrets Handling Rules

* All credentials, tokens, and passwords **must be vaulted**
* Vault files are visible, contents are encrypted
* Vault passwords are supplied **out-of-band**
* Secret variables must be used with `no_log: true`

If a value feels sensitive, **treat it as sensitive**.

---

## ⚠️ Competition Discipline

Under pressure, it is tempting to “just make it work.”

Do not:

* Duplicate variables “for speed”
* Override values in playbooks
* Guess where something *should* live

Correct placement now prevents outages later.

---

## ✅ Success Criteria

This file is being followed correctly if:

* You can locate any variable in seconds
* There is one authoritative definition per value
* Secrets are never exposed in logs or output
* Changes are deliberate and scoped

---

**This hierarchy is not optional.**
It is part of the defensive control surface of this repository.