# SSH Hardening Role

## Overview

Comprehensive SSH hardening role for CCDC competition environments. Implements security best practices to prevent unauthorized SSH access while maintaining legitimate connectivity.

## Features

### Security Hardening
- ✅ Disable root login via SSH
- ✅ Change root shell to `/bin/nologin`
- ✅ Lock root account (password login disabled)
- ✅ Disable password authentication (key-only)
- ✅ Disable empty passwords
- ✅ Disable X11 forwarding
- ✅ Strong cryptographic algorithms (ciphers, MACs, KEX)
- ✅ Connection timeout settings
- ✅ Rate limiting for authentication attempts

### Intrusion Prevention
- ✅ Fail2ban installation and configuration
- ✅ Automatic IP banning after failed attempts
- ✅ Customizable ban duration and thresholds

### Safety Features
- ✅ Pre-flight checks (SSH keys must exist)
- ✅ Configuration backup before changes
- ✅ Syntax validation before applying
- ✅ Post-change validation
- ✅ Graceful handling of missing prerequisites

## Requirements

- Ansible 2.15+
- SSH keys must be deployed before running (use `scripts/setup-ssh-keys.sh`)
- Target hosts: Ubuntu, Debian, Fedora, RHEL

## Quick Start

### 1. Ensure SSH Keys Are Deployed

```bash
# Run this FIRST to set up key-based authentication
./scripts/setup-ssh-keys.sh
```

### 2. Create Playbook

```yaml
---
- name: Harden SSH
  hosts: all
  become: true
  roles:
    - ssh_hardening
```

### 3. Run Playbook

```bash
ansible-playbook playbooks/04-ssh-hardening.yml
```

## Variables

### Core Settings

```yaml
# Disable password authentication (default: true)
ssh_hardening_disable_password_auth: true

# Lock root account (default: true)
ssh_hardening_lock_root_account: true

# Force hardening without SSH keys (DANGEROUS! default: false)
ssh_hardening_force_no_keys: false
```

### SSH Configuration

```yaml
# Service name (auto-detected)
ssh_hardening_service_name: "sshd"  # or "ssh" on Debian

# Config file path
ssh_hardening_config_path: /etc/ssh/sshd_config

# Security settings
ssh_hardening_max_auth_tries: 3
ssh_hardening_login_grace_time: 60
ssh_hardening_client_alive_interval: 300
```

### Fail2ban Settings

```yaml
# Enable fail2ban (default: true)
ssh_hardening_enable_fail2ban: true

# Ban duration (seconds)
ssh_hardening_fail2ban_bantime: 600  # 10 minutes

# Detection window (seconds)
ssh_hardening_fail2ban_findtime: 600  # 10 minutes

# Max retries before ban
ssh_hardening_fail2ban_maxretry: 3
```

### Cryptographic Settings

```yaml
# Strong ciphers
ssh_hardening_ciphers:
  - chacha20-poly1305@openssh.com
  - aes256-gcm@openssh.com
  - aes256-ctr

# Strong MACs
ssh_hardening_macs:
  - hmac-sha2-512-etm@openssh.com
  - hmac-sha2-256-etm@openssh.com

# Strong KEX algorithms
ssh_hardening_kex_algorithms:
  - curve25519-sha256
  - diffie-hellman-group-exchange-sha256
```

## Example Playbooks

### Basic Hardening

```yaml
---
- name: Basic SSH Hardening
  hosts: linux_servers
  become: true
  roles:
    - ssh_hardening
```

### Custom Configuration

```yaml
---
- name: SSH Hardening with Custom Settings
  hosts: critical_services
  become: true
  roles:
    - role: ssh_hardening
      vars:
        ssh_hardening_fail2ban_bantime: 3600  # 1 hour
        ssh_hardening_max_auth_tries: 2
```

### Skip Fail2ban

```yaml
---
- name: SSH Hardening Without Fail2ban
  hosts: all
  become: true
  roles:
    - role: ssh_hardening
      vars:
        ssh_hardening_enable_fail2ban: false
```

## Validation

### Pre-Hardening Checks

```bash
# Verify SSH keys are in place
ansible all -m command -a "ls -la /home/sysadmin/.ssh/authorized_keys"

# Validate SSH connectivity
ansible all -m ping

# Create VM snapshot in your practice environment (VMware)
# → Right-click VM → Snapshot → "Pre-SSH-Hardening"
```

### Post-Hardening Validation

```bash
# Validate SSH access with keys
ssh -i ~/.ssh/ccdc_rsa sysadmin@192.168.1.250

# Verify root login disabled
ssh root@192.168.1.250  # Should be rejected

# Check fail2ban status
ansible all -m command -a "fail2ban-client status sshd" -b

# Run validation playbook
ansible-playbook playbooks/01-validate-environment.yml
```

## Troubleshooting

### Problem: Locked Out After Hardening

**Cause:** SSH keys not deployed before disabling password auth

**Fix:**
1. Revert VM to a snapshot in your practice environment
2. Run `./scripts/setup-ssh-keys.sh` first
3. Re-run SSH hardening

### Problem: fail2ban Won't Start

**Cause:** Conflicting iptables rules or missing dependencies

**Fix:**
```bash
# Check fail2ban logs
ansible HOST -m command -a "journalctl -u fail2ban -n 50" -b

# Restart fail2ban manually
ansible HOST -m systemd -a "name=fail2ban state=restarted" -b
```

### Problem: SSH Configuration Invalid

**Cause:** Syntax error in sshd_config

**Fix:**
```bash
# Check SSH config syntax
ansible HOST -m command -a "/usr/sbin/sshd -t" -b

# Restore backup
ansible HOST -m copy -a "src=/etc/ssh/sshd_config.backup.XXXXX dest=/etc/ssh/sshd_config remote_src=yes" -b

# Restart SSH
ansible HOST -m systemd -a "name=sshd state=restarted" -b
```

## Competition Day Workflow

### First 5 Minutes

```bash
# 1. Deploy SSH keys to all reachable hosts
./scripts/setup-ssh-keys.sh

# 2. Create snapshots of all VMs in your practice environment
# (VMware → Snapshot → "Pre-Hardening")

# 3. Run SSH hardening
ansible-playbook playbooks/04-ssh-hardening.yml

# 4. Validate access still works
ansible-playbook playbooks/00-hello-world.yml
```

### If Hardening Fails

```bash
# Revert to a snapshot in your practice environment immediately
# VMware → Snapshot → Revert to "Pre-Hardening"

# Fix the issue (check logs)
ansible-playbook playbooks/01-validate-environment.yml

# Re-run hardening with verbose output
ansible-playbook playbooks/04-ssh-hardening.yml -vv
```

## What This Role Does

### ✅ Applied Changes

1. **Root Account:**
   - Shell changed to `/bin/nologin`
   - Direct SSH login disabled
   - Password login locked

2. **SSH Configuration:**
   - PermitRootLogin: `no`
   - PasswordAuthentication: `no`
   - PubkeyAuthentication: `yes`
   - PermitEmptyPasswords: `no`
   - X11Forwarding: `no`
   - Protocol: `2`

3. **Security Settings:**
   - MaxAuthTries: `3`
   - LoginGraceTime: `60s`
   - ClientAliveInterval: `300s`
   - Strong ciphers, MACs, KEX algorithms

4. **Fail2ban:**
   - SSH jail enabled
   - Ban after 3 failed attempts
   - 10-minute ban duration
   - iptables integration

### ❌ What This Role Does NOT Do

- Change SSH port (stays on 22 for scoring)
- Modify firewall rules (handled by firewall role)
- Configure SELinux/AppArmor (separate role)
- Install additional security tools (auditd, etc.)

## Dependencies

None. This role is self-contained.

## License

MIT

## Author

MWCCDC Team - Sprint 3

## Version

1.0.0 (Sprint 3 - Initial Release)
