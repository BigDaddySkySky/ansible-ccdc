# CCDC Ansible Automation - V2.0

> **"SSH connectivity first, everything else second."**  
> — Lesson learned from MWCCDC Invitational 2025

## What Failed at Invitational (V1.x)

1. **SSH connectivity issues** - Playbooks cited "unreachable"
2. **Messy bootstrap** - Team couldn't set up Python environment consistently
3. **No visibility** - Didn't know which hosts were reachable
4. **Poor communication** - Teammates didn't understand prerequisites

## V2.0 Core Principles

1. **Connectivity First:** Every playbook validates SSH before doing work
2. **Linux-Only Focus:** Windows is out of scope (too unreliable under pressure)
3. **Graceful Degradation:** Automation continues even if some hosts fail
4. **Priority-Based:** Focus on what's reachable, skip what's not
5. **Self-Documenting:** Every file has comments explaining "why"

## Quick Start (Competition Day)
```bash
# 1. Bootstrap Python environment (ONE COMMAND)
./scripts/bootstrap.sh

# 2. Activate virtual environment
source .venv/bin/activate

# 3. Check which hosts are reachable
ansible-playbook playbooks/01-validate-environment.yml

# 4. Run automation ONLY on reachable hosts
ansible-playbook playbooks/03-critical-path.yml --limit @reachable_hosts.txt
```

## Quick Start (Local Testing with VMware)
```bash
# 1. Create VMs in VMware Workstation (see docs/VM-SETUP.md)
# 2. Bootstrap
./scripts/bootstrap.sh
source .venv/bin/activate

# 3. Test against VMs
ansible-playbook -i inventory/staging.ini playbooks/00-hello-world.yml
```

## Repository Structure
```
ansible-ccdc-v2/
├── inventory/
│   ├── staging.ini          # VMware VMs for testing
│   └── production.ini       # Competition network (filled in day-of)
├── group_vars/              # Variables by logical group
│   └── all/                 # Global settings
├── playbooks/               # Numbered by execution order
│   ├── 00-hello-world.yml   # Simplest connectivity test
│   ├── 01-validate-environment.yml  # What's reachable?
│   └── 03-critical-path.yml # First 20 minutes (Sprint 3)
├── roles/                   # Reusable components (Sprint 4+)
├── scripts/                 # Helper automation
│   ├── bootstrap.sh         # Environment setup
│   └── test-sprint.sh       # Validate sprint deliverables
└── docs/                    # Design docs and guides
```

## Development Workflow

1. Work on `v2-rebuild` branch (not `main`)
2. Test changes in VMware VMs
3. Complete one sprint at a time
4. Run `./scripts/test-sprint.sh` to validate
5. Push to GitHub: `git push origin v2-rebuild`
6. Merge to `main` when V2.0 is proven stable

## Sprint Progress

- [x] Sprint 0.5: Foundation & Structure ← **YOU ARE HERE**
- [ ] Sprint 1: Inventory & SSH Priority
- [ ] Sprint 2: Secrets & Bootstrap Hardening
- [ ] Sprint 3: Critical Path (First 20 min)
- [ ] Sprint 4: Role Decomposition
- [ ] Sprint 5: Error Handling & Rollback
- [ ] Sprint 6: Team Training & Documentation

## What's NOT in V2.0

Based on invitational experience and time constraints:
- ❌ Windows automation (WinRM unreliable)
- ❌ Active Directory (manual is faster)
- ❌ Network devices (require manual password changes)
- ❌ Intrusion detection (manual setup faster)

**V2.0 Goal:** Secure Linux hosts in 20 minutes. Everything else is V2.1+.

## Tech Stack

- **Local Dev:** VMware Workstation Pro (Windows/Arch dual-boot)
- **Remote Dev:** GitHub Codespaces (editing only, no VMs)
- **Competition:** Ubuntu-based control node
- **Target Systems:** Ubuntu, Fedora, Debian Linux servers

## Learning Resources

- Git branching: See docs/GIT-EXPLAINED.md
- VMware setup: See docs/VM-SETUP.md
- Ansible basics: See docs/ANSIBLE-PRIMER.md