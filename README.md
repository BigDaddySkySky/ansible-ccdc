# MWCCDC Ansible Automation (Competition Repository)

> **Primary objective:** Secure reachable Linux services in the first ~20 minutes
> **Secondary objective:** Do no harm to scoring, access, or availability

This repository contains **competition-day automation only**.
It is intentionally strict, minimal, and opinionated.

---

## 🚨 Operator Assumptions (Read First)

This repo assumes:

* You are operating **after drop flag**
* You have **valid credentials** (SSH + sudo) for at least one Linux host
* You are running from a **Linux control node** (Ubuntu preferred)
* You are prioritizing **service uptime and scoring stability**

If any of the above are false, **do not proceed blindly**.

---

## 🎯 Design Principles

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

## 🚀 Competition-Day Quick Start

### 1️⃣ Bootstrap the control environment

Run once on the control node:

```bash
./scripts/bootstrap.sh
```

This prepares Python and Ansible in a virtual environment, validates vault configuration, and optionally deploys SSH keys (recommended).

---

### 2️⃣ Validate which hosts are reachable

Always do this before making changes:

```bash
ansible-playbook playbooks/01-validate-environment.yml
```

This identifies which hosts are reachable and safe to modify.

---

### 3️⃣ Run the critical path (first ~20 minutes)

```bash
ansible-playbook playbooks/04-critical-path.yml
```

This playbook operates only on validated hosts, applies competition-tested controls, and skips systems that would introduce risk.

---

## 📁 Repository Structure (Operator View)

```text
ansible-ccdc-v2/
├── scripts/          # Control-node helpers (bootstrap, diagnostics)
├── inventory/        # Competition inventory (filled in day-of)
├── group_vars/       # Group-level configuration
├── host_vars/        # Host-specific overrides
├── playbooks/        # Numbered execution order
└── roles/            # Modular hardening components
```

---

## 🔐 Secrets & Vault Handling (Important)

This repository uses **Ansible Vault** to protect sensitive values, including:

* Account passwords
* Service credentials
* Webhooks (e.g., Discord alerts)

**Key rules:**

* Vault passwords are **never stored in this repository**
* Vault files are visible but **contents are encrypted**
* All secret usage is guarded with `no_log: true`
* Vault passwords are provided **out-of-band** via `~/.vault_pass`

This is intentional and compliant with MWCCDC repository rules.

---

## ⚠️ What NOT to Do During Competition

Do **not**:

* Rename hosts or change IP addresses
* Run unnumbered or experimental playbooks
* Modify firewall rules unless explicitly instructed
* Rotate passwords blindly without validation
* Run automation on hosts you cannot recover manually

If unsure, **pause and reassess**. Automation is a tool, not a mandate.

---

## 🧭 When to Stop

Stop automation immediately if:

* SSH access is lost to a critical host
* A scored service becomes unavailable
* White Team guidance conflicts with automation behavior

At that point, **manual intervention takes priority**.

---

## ✅ Success Criteria

You are succeeding in the first phase if:

* SSH access is preserved
* Services remain available
* Credentials are controlled
* Telemetry (Splunk, logs) is flowing
* You can explain every change made

---

## 📌 Final Note

This repository is designed to:

> **Buy you time, not win the competition for you.**

Use it deliberately, understand its limits, and always prioritize scoring stability.