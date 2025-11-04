# CCDC Ansible Automation - V2.0

**"SSH connectivity first, everything else second."**  
— Lesson learned from MWCCDC Invitational 2025

## What's Different in V2.0

### V1.x Problems (Invitational Postmortem)
1. **SSH unreachable hosts** - automation failed because we couldn't connect
2. **Messy bootstrap** - Python environment setup was inconsistent
3. **No connectivity priority** - didn't know which hosts to focus on
4. **Poor team communication** - teammates didn't understand critical requirements

### V2.0 Core Principles
1. **Connectivity First:** Every playbook starts with connection validation
2. **Graceful Degradation:** Automation continues even if some hosts unreachable
3. **Priority-Based:** Focus on reachable hosts, skip unreachable ones
4. **Self-Documenting:** Every playbook explains what it does and why

## Quick Start (Competition Day)
```bash
# 1. Bootstrap Python environment (ONE COMMAND)
./scripts/bootstrap.sh

# 2. Activate virtual environment
source .venv/bin/activate

# 3. Check which hosts are reachable
ansible-playbook playbooks/01-validate-environment.yml

# 4. Establish SSH to critical hosts first
ansible-playbook playbooks/02-establish-connectivity.yml

# 5. Run automation on reachable hosts only
ansible-playbook playbooks/XX-critical-path.yml --limit @reachable_hosts.txt
```

## Quick Start (Local Development)
```bash
# 1. Set up VMs (see docs/VM-SETUP.md)
./scripts/setup-vms.sh

# 2. Bootstrap
./scripts/bootstrap.sh
source .venv/bin/activate

# 3. Test against staging
ansible-playbook -i inventory/staging.ini playbooks/00-hello-world.yml
```

## Repository Structure
```
ansible-ccdc-v2/
├── inventory/
│   ├── staging.ini          # Local VMs for testing
│   └── production.ini       # Competition network (updated day-of)
├── group_vars/              # Variables by logical group
├── playbooks/               # Numbered by execution order
│   ├── 00-hello-world.yml   # Simplest connectivity test
│   ├── 01-validate-environment.yml  # What's reachable?
│   └── 02-establish-connectivity.yml  # Fix SSH issues
├── roles/                   # Reusable components (Sprint 4+)
├── scripts/                 # Helper automation
└── docs/                    # Design docs
```

## Development Workflow

1. Work on `v2-rebuild` branch
2. Test changes on local VMs
3. Complete sprint deliverables
4. Run `./scripts/test-sprint.sh`
5. Push to GitHub when sprint complete

## Sprint Progress

- [x] Sprint 0.5: Foundation & Structure ← **YOU ARE HERE**
- [ ] Sprint 1: Inventory & SSH Priority
- [ ] Sprint 2: Secrets & Bootstrap Hardening
- [ ] Sprint 3: Critical Path (First 20 min)
- [ ] Sprint 4: Role Decomposition
- [ ] Sprint 5: Error Handling & Rollback
- [ ] Sprint 6: Team Training & Documentation

## What's NOT in V2.0

Based on invitational experience, these are **out of scope** until V2.0 is rock-solid:
- Active Directory automation (manual is fine)
- Windows automation (WinRM too unreliable under pressure)
- Network device automation (requires manual password changes anyway)
- Intrusion detection (manual setup faster)

**V2.0 Goal:** Get Linux hosts secured in 20 minutes. Everything else is bonus.

## Environment Support

- **Local Development:** Arch Linux + KVM/libvirt
- **Remote Development:** GitHub Codespaces (testing limited)
- **Competition:** Ubuntu/Debian-based control node
