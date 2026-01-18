# Firewall Hardening Role

## Overview

Comprehensive host-based firewall configuration role for CCDC competition environments. Automatically configures ufw (Ubuntu/Debian) or firewalld (Fedora/RHEL) based on operating system, allowing only scored services while blocking all other inbound traffic.

## Features

### Security Hardening
- ✅ Default deny incoming traffic
- ✅ Allow only scored services (HTTP, HTTPS, SMTP, POP3, FTP, DNS, SSH)
- ✅ Kernel-level DDoS protection (SYN cookies, IP forwarding disabled)
- ✅ Rate limiting for SSH connections
- ✅ Scoring engine IP whitelist support
- ✅ Comprehensive firewall logging

### Cross-Platform Support
- ✅ UFW (Ubuntu, Debian)
- ✅ Firewalld (Fedora, RHEL, CentOS)
- ✅ Automatic backend detection
- ✅ Unified configuration interface

### Safety Features
- ✅ Pre-flight checks (ensures SSH remains accessible)
- ✅ SSH connectivity validation
- ✅ Comprehensive post-configuration validation
- ✅ Rollback-friendly (VM snapshots recommended in your practice environment)

## Requirements

- Ansible 2.15+
- Target hosts: Ubuntu, Debian, Fedora, RHEL
- SSH access must be configured before running (see SSH hardening role)

## Quick Start

### 1. Create Playbook

```yaml
---
- name: Configure Firewall
  hosts: all
  become: true
  roles:
    - firewall
```

### 2. Run Playbook

```bash
ansible-playbook playbooks/05-firewall-hardening.yml
```

## Variables

### Core Settings

```yaml
# Auto-detect firewall backend (ufw or firewalld)
firewall_backend: "{{ 'ufw' if ansible_os_family == 'Debian' else 'firewalld' }}"

# Enable/disable firewall
firewall_enabled: true

# Default policies
firewall_default_incoming: deny
firewall_default_outgoing: allow
firewall_default_forward: deny
```

### Scored Services

```yaml
# Services that must remain accessible for scoring
firewall_scored_services:
  - name: ssh
    port: 22
    proto: tcp
  - name: http
    port: 80
    proto: tcp
  - name: https
    port: 443
    proto: tcp
  - name: smtp
    port: 25
    proto: tcp
  - name: pop3
    port: 110
    proto: tcp
  - name: ftp
    port: 21
    proto: tcp
  - name: dns
    port: 53
    proto: udp
```

### Additional Services (Host-Specific)

```yaml
# Add services not in the default scored list
firewall_additional_services:
  - name: mysql
    port: 3306
    proto: tcp
    comment: "MySQL database"
  - name: postgresql
    port: 5432
    proto: tcp
    comment: "PostgreSQL database"
```

### Scoring Engine Access

```yaml
# Allow traffic from scoring engine IPs
firewall_scoring_ips:
  - "172.31.0.0/16"      # CCDC scoring range
  - "192.168.0.0/16"     # Local network

# White Team access (if specified)
firewall_whiteteam_ips: []
```

### Rate Limiting

```yaml
# Enable rate limiting
firewall_enable_rate_limiting: true

# SSH connections per minute
firewall_ssh_rate_limit: "10/minute"

# HTTP/HTTPS connections per minute
firewall_http_rate_limit: "30/minute"
```

### Logging

```yaml
# Enable logging
firewall_enable_logging: true

# Log level (low/medium/high for ufw, notice/info/debug for firewalld)
firewall_log_level: "{{ 'low' if ansible_os_family == 'Debian' else 'notice' }}"

# Log denied packets
firewall_log_denied: true

# Log accepted packets (verbose)
firewall_log_accepted: false
```

### Kernel Hardening

```yaml
# Enable SYN flood protection
firewall_enable_syn_protection: true

# Block ICMP ping (may impact scoring)
firewall_block_icmp: false
```

## Example Playbooks

### Basic Firewall Configuration

```yaml
---
- name: Basic Firewall Hardening
  hosts: linux_servers
  become: true
  roles:
    - firewall
```

### Web Server with Custom Services

```yaml
---
- name: Web Server Firewall
  hosts: web_servers
  become: true
  roles:
    - role: firewall
      vars:
        firewall_additional_services:
          - name: mysql
            port: 3306
            proto: tcp
            comment: "MySQL for web app"
```

### Mail Server Configuration

```yaml
---
- name: Mail Server Firewall
  hosts: mail_servers
  become: true
  roles:
    - role: firewall
      vars:
        firewall_additional_services:
          - name: imap
            port: 143
            proto: tcp
            comment: "IMAP mail access"
          - name: imaps
            port: 993
            proto: tcp
            comment: "IMAP over SSL"
```

### High Security (Aggressive Rate Limiting)

```yaml
---
- name: High Security Firewall
  hosts: critical_services
  become: true
  roles:
    - role: firewall
      vars:
        firewall_ssh_rate_limit: "5/minute"
        firewall_http_rate_limit: "20/minute"
        firewall_enable_syn_protection: true
```

## Validation

### Pre-Hardening Checks

```bash
# Verify SSH access
ansible all -m ping

# Create VM snapshots in your practice environment (VMware)
# → Right-click VM → Snapshot → "Pre-Firewall-Hardening"

# Validate current service accessibility
curl http://192.168.1.250
telnet 192.168.1.250 25
```

### Post-Hardening Validation

```bash
# Verify firewall is active
ansible all -m command -a "ufw status" -b          # Ubuntu
ansible all -m command -a "firewall-cmd --state" -b # Fedora

# Validate SSH still works
ansible all -m ping

# Validate scored services
curl http://192.168.1.250                    # HTTP
curl https://192.168.1.250                   # HTTPS
telnet 192.168.1.250 25                      # SMTP
telnet 192.168.1.250 110                     # POP3
ftp 192.168.1.250                            # FTP
dig @192.168.1.250 example.com               # DNS

# Check firewall logs (Ubuntu)
ansible HOST -m command -a "tail -50 /var/log/ufw.log" -b

# Check firewall logs (Fedora)
ansible HOST -m command -a "journalctl -u firewalld -n 50" -b
```

## Troubleshooting

### Problem: Locked Out After Firewall Activation

**Cause:** SSH not properly allowed in firewall rules

**Fix:**
1. Revert VM to a snapshot in your practice environment
2. Verify SSH is in `firewall_scored_services`
3. Run playbook with verbose output: `-vv`
4. Re-validate connectivity before locking yourself out

### Problem: Scored Services Unreachable

**Cause:** Firewall blocking required ports

**Fix:**
```bash
# Check firewall rules (Ubuntu)
ansible HOST -m command -a "ufw status numbered" -b

# Check firewall rules (Fedora)
ansible HOST -m command -a "firewall-cmd --list-all" -b

# Temporarily allow service manually
ansible HOST -m command -a "ufw allow 80/tcp" -b          # Ubuntu
ansible HOST -m command -a "firewall-cmd --add-port=80/tcp --permanent" -b  # Fedora

# Re-run playbook to fix permanently
ansible-playbook playbooks/05-firewall-hardening.yml --limit HOST
```

### Problem: Rate Limiting Too Aggressive

**Cause:** SSH rate limit blocking legitimate connections

**Fix:**
```yaml
# Increase rate limit in host_vars
firewall_ssh_rate_limit: "20/minute"  # More permissive

# Or disable rate limiting entirely
firewall_enable_rate_limiting: false
```

### Problem: Firewall Logs Missing

**Cause:** Logging not enabled or wrong log location

**Fix:**
```bash
# Enable logging (Ubuntu)
ansible HOST -m command -a "ufw logging on" -b

# Check log location (Ubuntu)
ansible HOST -m command -a "ls -la /var/log/ufw*" -b

# Check log location (Fedora)
ansible HOST -m command -a "journalctl -u firewalld | tail -50" -b
```

## Competition Day Workflow

### First 10 Minutes

```bash
# 1. Ensure SSH hardening is complete
ansible-playbook playbooks/04-ssh-hardening.yml

# 2. Create firewall snapshots in your practice environment
# (VMware → Snapshot → "Pre-Firewall")

# 3. Run firewall hardening
ansible-playbook playbooks/05-firewall-hardening.yml

# 4. Immediately validate all scored services
./scripts/test-scored-services.sh
```

### If Firewall Breaks Services

```bash
# Disable firewall temporarily (Ubuntu)
ansible HOST -m command -a "ufw disable" -b

# Disable firewall temporarily (Fedora)
ansible HOST -m command -a "systemctl stop firewalld" -b

# Fix configuration
# Re-enable
ansible HOST -m command -a "ufw enable" -b              # Ubuntu
ansible HOST -m command -a "systemctl start firewalld" -b  # Fedora
```

## What This Role Does

### ✅ Applied Changes

1. **Kernel Security:**
   - SYN cookies enabled (SYN flood protection)
   - IP forwarding disabled
   - Source address verification enabled
   - ICMP redirects disabled
   - Martian packet logging enabled

2. **Firewall Configuration:**
   - Default incoming: DENY
   - Default outgoing: ALLOW
   - SSH: ALLOWED (with rate limiting)
   - Scored services: ALLOWED
   - All other ports: BLOCKED

3. **UFW (Ubuntu):**
   - Reset to defaults
   - Configure policies
   - Allow scored services
   - Enable logging
   - Activate firewall

4. **Firewalld (Fedora):**
   - Set default zone
   - Remove default services
   - Allow scored services by port
   - Configure rich rules for rate limiting
   - Enable logging

### ❌ What This Role Does NOT Do

- Configure application-level firewalls (mod_security, etc.)
- Modify network device firewalls (Palo Alto, Cisco FTD)
- Configure SELinux/AppArmor rules (separate role)
- Set up IDS/IPS systems (auditd role)

## Dependencies

- `community.general` (for ufw module)
- `ansible.posix` (for firewalld and sysctl modules)

Install with:
```bash
ansible-galaxy collection install community.general ansible.posix
```

## License

MIT

## Author

MWCCDC Team - Sprint 3.2

## Version

1.0.0 (Sprint 3.2 - Initial Release)
