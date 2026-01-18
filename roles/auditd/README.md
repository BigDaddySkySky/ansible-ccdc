# Auditd Monitoring Role

## Overview

Comprehensive auditd-based intrusion detection and file integrity monitoring role for CCDC competition environments. Automatically detects unauthorized changes, privilege escalation attempts, authentication failures, and suspicious activity across Ubuntu and Fedora systems.

## Features

### File Integrity Monitoring
- ✅ Monitor 11+ critical system files (SSH config, passwd/shadow, sudoers)
- ✅ Detect modifications to boot directory (kernel tampering)
- ✅ Track firewall rule changes (ufw/firewalld)
- ✅ Watch critical directories (/etc, /usr/bin, /usr/sbin)
- ✅ Alert on suspicious file deletions

### Privilege Escalation Detection
- ✅ Monitor sudo/su usage
- ✅ Track setuid binary execution
- ✅ Detect kernel module loading
- ✅ Log capability changes
- ✅ Alert on unauthorized privilege escalation

### Authentication Tracking
- ✅ Monitor SSH login attempts (success/failure)
- ✅ Track user creation/deletion
- ✅ Record password changes
- ✅ Log session events (utmp/wtmp/btmp)
- ✅ Detect authentication bypass attempts

### Discord Integration
- ✅ Real-time alerts for critical events
- ✅ Hourly audit summaries
- ✅ Automated webhook notifications
- ✅ Event correlation and reporting

### Evidence Collection
- ✅ Automated log archival
- ✅ Compression support
- ✅ NISE inject preparation
- ✅ Structured evidence directory

### Cross-Platform Support
- ✅ Ubuntu (auditd + audispd-plugins)
- ✅ Fedora (audit + audit-libs)
- ✅ Automatic package manager detection
- ✅ Platform-specific optimizations

## Requirements

- Ansible 2.15+
- Target hosts: Ubuntu, Debian, Fedora, RHEL
- Minimum disk space: 500MB in /var/log
- SSH access with sudo privileges

## Quick Start

### 1. Create Playbook

```yaml
---
- name: Configure Auditd Monitoring
  hosts: all
  become: true
  roles:
    - auditd
```

### 2. Run Playbook

```bash
# Test on single host first
ansible-playbook playbooks/06-auditd-monitoring.yml --limit ubuntu_ecom_vm

# Deploy to all hosts
ansible-playbook playbooks/06-auditd-monitoring.yml
```

## Variables

### Core Settings

```yaml
# Enable auditd
auditd_enabled: true

# Service name
auditd_service_name: auditd

# Log file location
auditd_log_file: /var/log/audit/audit.log

# Maximum log file size (MB)
auditd_max_log_file: 100

# Number of log files to retain
auditd_num_logs: 5
```

### File Integrity Monitoring

```yaml
# Critical files to monitor (default: 11 files)
auditd_monitored_files:
  - path: /etc/ssh/sshd_config
    key: sshd_config
    perm: wa
    comment: "SSH daemon configuration"
  
  - path: /etc/passwd
    key: passwd_changes
    perm: wa
    comment: "User account database"
  
  # ... 9 more critical files

# Monitor critical directories
auditd_monitor_critical_dirs: true

auditd_critical_directories:
  - /etc
  - /usr/bin
  - /usr/sbin
  - /bin
  - /sbin
```

### Privilege Escalation Settings

```yaml
# Monitor sudo usage
auditd_monitor_sudo: true

# Monitor su usage
auditd_monitor_su: true

# Monitor setuid execution
auditd_monitor_setuid: true

# Monitor capability changes
auditd_monitor_capabilities: true

# Monitor kernel module loading
auditd_monitor_kernel_modules: true
```

### Authentication Settings

```yaml
# Monitor SSH logins
auditd_monitor_ssh_logins: true

# Monitor failed logins
auditd_monitor_failed_logins: true

# Monitor user management
auditd_monitor_user_mgmt: true

# Monitor group changes
auditd_monitor_group_mgmt: true
```

### Discord Webhook Settings

```yaml
# Enable Discord alerts
auditd_enable_discord_alerts: true

# Discord webhook URL (from vault)
auditd_discord_webhook: "{{ vault_discord_webhook_url }}"

# Alert triggers
auditd_alert_priv_esc: true
auditd_alert_auth_failures: true
auditd_alert_file_changes: true
```

### Evidence Collection

```yaml
# Enable automated evidence collection
auditd_enable_evidence_collection: true

# Evidence directory
auditd_evidence_dir: /var/log/ccdc-evidence

# Compress archives
auditd_compress_evidence: true
```

## Example Playbooks

### Basic Monitoring

```yaml
---
- name: Basic Auditd Monitoring
  hosts: linux_servers
  become: true
  roles:
    - auditd
```

### Custom File Monitoring

```yaml
---
- name: Auditd with Custom File Monitoring
  hosts: web_servers
  become: true
  roles:
    - role: auditd
      vars:
        auditd_monitored_files:
          - path: /var/www/html
            key: webroot_changes
            perm: wa
            comment: "Web root directory"
          - path: /etc/nginx
            key: nginx_config
            perm: wa
            comment: "Nginx configuration"
```

### High-Security Configuration

```yaml
---
- name: High-Security Auditd Configuration
  hosts: critical_services
  become: true
  roles:
    - role: auditd
      vars:
        auditd_max_log_file: 500  # Larger logs
        auditd_num_logs: 20       # More retention
        auditd_monitor_file_deletion: true
        auditd_alert_priv_esc: true
        auditd_alert_auth_failures: true
```

### Disable Discord Alerts

```yaml
---
- name: Auditd Without Discord
  hosts: all
  become: true
  roles:
    - role: auditd
      vars:
        auditd_enable_discord_alerts: false
```

## Validation

### Pre-Deployment Checks

```bash
# Verify SSH/firewall working
ansible-playbook playbooks/01-validate-environment.yml

# Check disk space
ansible all -m shell -a "df -h /var/log" -b

# Create VM snapshots in your practice environment
# VMware → Right-click VM → Snapshot → "Pre-Auditd-Monitoring"
```

### Post-Deployment Validation

```bash
# Verify service is active
ansible all -m command -a "systemctl status auditd" -b

# Check loaded rules count
ansible all -m command -a "auditctl -l | wc -l" -b
# Expected: 100+ rules

# View loaded rules
ansible all -m command -a "auditctl -l" -b

# Check log file exists
ansible all -m stat -a "path=/var/log/audit/audit.log" -b

# View recent events
ansible all -m command -a "ausearch -ts recent | head -20" -b
```

### Generate Validation Events

```bash
# Validate file integrity monitoring
ansible HOST -m command -a "touch /etc/validation-audit-file" -b
ansible HOST -m command -a "ausearch -k file_integrity" -b

# Validate privilege escalation detection
ansible HOST -m command -a "sudo ls /root" -b
ansible HOST -m command -a "ausearch -k sudo_execution" -b

# Validate authentication monitoring
ssh sysadmin@HOST  # Trigger SSH login event
ansible HOST -m command -a "ausearch -k sshd_execution" -b
```

### Discord Webhook Validation

```bash
# Check if validation alert was sent (during deployment)
# Look for "Auditd Monitoring Active" message in Discord

# Manually trigger alert
ansible HOST -m command -a "/usr/local/bin/ccdc-audit-alerts/send-discord-alert.py 'Validation Alert' 'Manual validation from Ansible'" -b
```

## Troubleshooting

### Problem: Auditd Service Won't Start

**Cause:** Configuration syntax error or conflicting rules

**Fix:**
```bash
# Check service logs
ansible HOST -m command -a "journalctl -u auditd -n 50" -b

# Validate configuration
ansible HOST -m command -a "auditd -t" -b

# Restore backup
ansible HOST -m copy -a "src=/etc/audit/auditd.conf.backup.XXXXX dest=/etc/audit/auditd.conf remote_src=yes" -b

# Restart service
ansible HOST -m systemd -a "name=auditd state=restarted" -b
```

### Problem: Rules Not Loading

**Cause:** Syntax error in audit rules

**Fix:**
```bash
# Check for syntax errors
ansible HOST -m command -a "auditctl -l" -b

# Manually load rules
ansible HOST -m command -a "augenrules --load" -b

# View rules files
ansible HOST -m command -a "ls -la /etc/audit/rules.d/" -b
ansible HOST -m command -a "cat /etc/audit/rules.d/10-file-integrity.rules" -b
```

### Problem: Logs Growing Too Fast

**Cause:** High event volume, insufficient log rotation

**Fix:**
```yaml
# Reduce log size and increase rotation
auditd_max_log_file: 50      # Smaller files
auditd_num_logs: 10           # More files
auditd_rate_limit: 1000       # Limit events/sec

# Or filter noisy events
# Edit rules to exclude specific syscalls
```

### Problem: Discord Alerts Not Working

**Cause:** Invalid webhook URL or network connectivity

**Fix:**
```bash
# Validate webhook manually
ansible HOST -m shell -a "/usr/local/bin/ccdc-audit-alerts/send-discord-alert.py 'Validation' 'Manual validation'" -b

# Check webhook URL
ansible-vault view group_vars/all/vault.yml | grep discord

# Validate network connectivity
ansible HOST -m uri -a "url=https://discord.com/api status_code=200" -b

# Check script permissions
ansible HOST -m stat -a "path=/usr/local/bin/ccdc-audit-alerts/send-discord-alert.py" -b
```

### Problem: High CPU Usage

**Cause:** Too many audit rules or aggressive monitoring

**Fix:**
```yaml
# Reduce monitoring scope
auditd_monitor_file_deletion: false
auditd_monitor_critical_dirs: false

# Increase buffer size
auditd_buffer_size: 16384

# Add rate limiting
auditd_rate_limit: 500
```

## Competition Day Workflow

### First 5 Minutes (After SSH/Firewall)

```bash
# 1. Create snapshots in your practice environment
# VMware → Snapshot → "Pre-Auditd"

# 2. Deploy auditd
ansible-playbook playbooks/06-auditd-monitoring.yml

# 3. Validate immediately
ansible all -m command -a "auditctl -l | wc -l" -b
# Expected: 100+ rules

# 4. Verify Discord alerts
# Check Discord for "Auditd Monitoring Active" message
```

### During Competition

```bash
# Monitor for suspicious activity
ansible all -m command -a "ausearch -k privilege_escalation -ts recent" -b
ansible all -m command -a "ausearch -k file_integrity -ts recent" -b
ansible all -m command -a "aureport --auth --summary" -b

# Collect evidence for NISE inject
ansible HOST -m shell -a "ausearch -ts <TIME> > /var/log/ccdc-evidence/incident-$(date +%s).log" -b
```

### If Red Team Detected

```bash
# Identify compromised accounts
ansible all -m command -a "aureport --auth --summary" -b

# Find modified files
ansible all -m command -a "ausearch -k file_integrity" -b

# Track privilege escalation
ansible all -m command -a "ausearch -k sudo_execution" -b

# Generate incident report
ansible all -m command -a "aureport --file" -b
```

## What This Role Does

### ✅ Applied Changes

1. **Packages Installed:**
   - Ubuntu: auditd, audispd-plugins
   - Fedora: audit, audit-libs

2. **Configuration Files:**
   - `/etc/audit/auditd.conf` - Daemon configuration
   - `/etc/audit/rules.d/10-file-integrity.rules` - File monitoring
   - `/etc/audit/rules.d/20-privilege-escalation.rules` - Priv esc detection
   - `/etc/audit/rules.d/30-authentication.rules` - Auth tracking
   - `/etc/audit/rules.d/99-finalize.rules` - System configuration

3. **Monitoring Active:**
   - 11+ critical files watched
   - 4 critical directories monitored
   - Privilege escalation detection enabled
   - Authentication tracking active
   - 100+ audit rules loaded

4. **Discord Integration:**
   - Alert script: `/usr/local/bin/ccdc-audit-alerts/send-discord-alert.py`
   - Hourly summary: Cron job active
   - Real-time critical event alerts

5. **Evidence Collection:**
   - Directory: `/var/log/ccdc-evidence`
   - Automated log archival
   - Compression enabled

### ❌ What This Role Does NOT Do

- Configure SIEM integration (Splunk, etc.)
- Implement real-time alerting (beyond Discord)
- Provide audit log analysis (manual analysis required)
- Configure remote syslog forwarding
- Implement automated incident response

## Useful Commands

### View Audit Logs

```bash
# Tail live log
tail -f /var/log/audit/audit.log

# Search by key
ausearch -k file_integrity
ausearch -k privilege_escalation
ausearch -k sudo_execution
ausearch -k auth_failures

# Search by time
ausearch -ts recent           # Last 10 minutes
ausearch -ts today            # Since midnight
ausearch -ts 10:00:00         # Since 10 AM
ausearch -ts yesterday        # Previous day
```

### Generate Reports

```bash
# Summary report
aureport --summary

# Authentication report
aureport --auth

# File access report
aureport --file

# Failed events
aureport --failed --summary

# Top 10 events
aureport --event --summary | head -15
```

### Manage Rules

```bash
# View loaded rules
auditctl -l

# Count rules
auditctl -l | wc -l

# Reload rules from files
augenrules --load

# Delete all rules (temporary)
auditctl -D

# Test event generation
auditctl -m "Test message"
```

## Dependencies

- `ansible.posix` collection (for sysctl module)
- `community.general` collection (for service management)

Install with:
```bash
ansible-galaxy collection install ansible.posix community.general
```

## License

MIT

## Author

MWCCDC Team - Sprint 3.3

## Version

1.0.0 (Sprint 3.3 - Initial Release)

## Additional Resources

- [Linux Audit Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/security_guide/chap-system_auditing)
- [Auditd Best Practices](https://security.blogoverflow.com/2013/01/a-brief-introduction-to-auditd/)
- [NIST Audit Guidelines](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-92.pdf)
