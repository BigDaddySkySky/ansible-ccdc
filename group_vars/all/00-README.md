# Variable Hierarchy Explanation

## The Problem We're Solving

In V1.x, variables were scattered everywhere. Nobody knew where to look for passwords, IPs, or config values. This caused:
- Duplicate definitions
- Conflicting values
- Confusion during time pressure

## V2.0 Rules

### Use `group_vars/all/` for:
- Global constants (ports, paths)
- Competition metadata (team number)
- Secrets that ALL hosts need (Discord webhook)

### Use `group_vars/<group>/` for:
- Group-specific settings (packages, services)
- Credentials shared within a group

### Use `host_vars/<hostname>/` for:
- Host-unique configuration
- Host-unique credentials

### NEVER use:
- Playbook-level vars (except for temporary logic)
- Hardcoded values in tasks

## Example: Where Does This Go?

**SSH Port (used by all hosts):**
→ `group_vars/all/ports.yml` as `ssh_port: 22`

**Ubuntu package list:**
→ `group_vars/linux/packages.yml`

**Splunk admin password (unique):**
→ `host_vars/splunk/vault.yml` (encrypted)

**Discord webhook (shared by all):**
→ `group_vars/all/vault.yml` (encrypted)