# CCDC Ansible Automation - V2.0

> **Rebuilt from the ground up after MWCCDC Invitational 2025**

## What's Different in V2.0

### V1.x Problems (Why It Failed)
- Overly complex role dependencies
- Manual steps broke automation flow
- Team couldn't understand playbook order
- Too many "nice-to-have" features
- Vault management was confusing
- Bootstrap didn't catch configuration errors

### V2.0 Principles
1. **Inject-First Design:** Every playbook solves a specific inject or failure scenario
2. **Testability:** Every change is tested on VMs before competition
3. **Teammate Onboarding:** Any teammate can run automation in 5 minutes
4. **Fail-Safe:** Automation never makes things worse
5. **Incremental:** Work in sprints, test each sprint, merge when ready

## Quick Start (Competition Day)
```bash
# 1. Bootstrap (run once)
./scripts/bootstrap.sh

# 2. Validate environment
ansible-playbook playbooks/01-validate-environment.yml

# 3. Run first 20 minutes automation
ansible-playbook playbooks/XX-critical-path.yml  # (Sprint 3)
```

## Quick Start (Development/Testing)
```bash
# 1. Set up VMs (see docs/VM-SETUP.md)
# 2. Test against staging inventory
ansible-playbook -i inventory/staging.ini playbooks/00-hello-world.yml
```

## Repository Structure

- `inventory/` - Host definitions (production vs staging)
- `group_vars/` - Variables organized by logical group
- `playbooks/` - Numbered by execution order
- `roles/` - Reusable components (added in Sprint 4)
- `scripts/` - Helper scripts for common tasks
- `docs/` - Design docs and guides

## Development Workflow

1. Work on `v2-rebuild` branch
2. Complete one sprint at a time
3. Test sprint deliverables: `./scripts/test-sprint.sh`
4. Merge to main when sprint is validated

## Sprint Progress

- [x] Sprint 0.5: Foundation & Structure
- [ ] Sprint 1: Inventory & Discovery
- [ ] Sprint 2: Secrets & Bootstrap
- [ ] Sprint 3: Critical Path (First 20 min)
- [ ] Sprint 4: Role Decomposition
- [ ] Sprint 5: Error Handling
- [ ] Sprint 6: Documentation & Training

## What's NOT in V2.0 (Yet)

- Active Directory password resets (too complex, manual is fine)
- Intrusion detection automation (manual setup is faster)
- Network device automation (requires manual password changes anyway)
- Windows automation (WinRM reliability issues)

These may be added in V2.1+ after V2.0 is proven stable.