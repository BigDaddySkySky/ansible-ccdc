# Sprint 3: Service Hardening - SSH

## 🎯 Sprint Goals

1. ✅ Create SSH hardening role with comprehensive security controls
2. ⏳ Implement firewall configuration (ufw/firewalld)
3. ⏳ Set up auditd monitoring
4. ⏳ Configure Discord webhook alerts for security events
5. ⏳ Integrate with NISE scoring validation

**Current Status:** SSH Hardening Complete ✅

---

## 📋 Deliverables - SSH Hardening

### ✅ Completed

- [x] `roles/ssh_hardening/` - Complete SSH hardening role
  - [x] `tasks/main.yml` - Main orchestration
  - [x] `tasks/preflight.yml` - Pre-flight safety checks
  - [x] `tasks/root_hardening.yml` - Root account security
  - [x] `tasks/ssh_config.yml` - SSH daemon configuration
  - [x] `tasks/fail2ban.yml` - Intrusion prevention
  - [x] `tasks/validate.yml` - Post-hardening validation
  - [x] `defaults/main.yml` - Configurable variables
  - [x] `handlers/main.yml` - Service restart handlers
  - [x] `templates/jail.local.j2` - Fail2ban configuration
  - [x] `meta/main.yml` - Role metadata
  - [x] `README.md` - Complete documentation
- [x] `playbooks/04-ssh-hardening.yml` - SSH hardening playbook
- [x] Documentation for Sprint 3

---

## 🔐 SSH Hardening Features

### Security Controls Implemented

1. **Root Account Hardening:**
   - Root login via SSH disabled
   - Root shell changed to `/bin/nologin`
   - Root account password login locked

2. **SSH Authentication:**
   - Password authentication disabled (key-only)
   - Public key authentication enforced
   - Empty passwords forbidden
   - Maximum 3 authentication attempts

3. **Connection Security:**
   - X11 forwarding disabled
   - Protocol 2 only (Protocol 1 disabled)
   - Connection timeouts configured
   - Rate limiting for new connections

4. **Cryptographic Hardening:**
   - Strong ciphers only (chacha20-poly1305, aes256-gcm, etc.)
   - Strong MACs (hmac-sha2-512-etm, hmac-sha2-256-etm)
   - Strong key exchange algorithms (curve25519-sha256, etc.)

5. **Intrusion Prevention:**
   - Fail2ban installed and configured
   - Automatic IP banning after 3 failed attempts
   - 10-minute ban duration
   - iptables integration

### Safety Features

- ✅ Pre-flight checks verify SSH keys exist
- ✅ Configuration backup before changes
- ✅ Syntax validation before applying
- ✅ Post-change connectivity validation
- ✅ Rollback instructions if locked out

---

## 🧪 Testing & Validation

### Prerequisites

```bash
# 1. Ensure SSH keys are deployed
./scripts/setup-ssh-keys.sh

# 2. Verify connectivity
ansible-playbook playbooks/00-hello-world.yml

# 3. Create VM snapshots
# VMware → Right-click VM → Snapshot → "Pre-SSH-Hardening"
```

### Test 1: Dry Run (Check Mode)

```bash
# See what would change without applying
ansible-playbook playbooks/04-ssh-hardening.yml --check
```

### Test 2: Single Host

```bash
# Test on one VM first
ansible-playbook playbooks/04-ssh-hardening.yml --limit ubuntu_ecom_vm

# Verify SSH still works
ssh -i ~/.ssh/ccdc_rsa sysadmin@192.168.1.250
```

### Test 3: All Hosts

```bash
# Apply to all VMs
ansible-playbook playbooks/04-ssh-hardening.yml

# Verify connectivity
ansible all -m ping
```

### Test 4: Validation Checks

```bash
# Check root shell
ansible all -m command -a "getent passwd root | cut -d: -f7" -b
# Expected: /bin/nologin

# Verify root login disabled
ansible all -m shell -a "grep '^PermitRootLogin no' /etc/ssh/sshd_config" -b
# Expected: PermitRootLogin no

# Check fail2ban status
ansible all -m command -a "fail2ban-client status sshd" -b
# Expected: Jail status output

# Test password auth is disabled
ssh sysadmin@192.168.1.250
# Expected: Permission denied (publickey)
```

---

## 📊 Sprint Metrics

**Role Structure:**
- 6 task files (main, preflight, root_hardening, ssh_config, fail2ban, validate)
- 1 handler file (sshd and fail2ban restart)
- 1 template (fail2ban jail configuration)
- 1 defaults file (50+ configurable variables)
- 1 comprehensive README

**Security Improvements:**
- Before: Root SSH login allowed, password auth enabled
- After: Root disabled, key-only auth, fail2ban active

**Lines of Code:** ~850 lines across all role files

**Testing Time:** ~3-5 minutes per host

---

## 🎓 Lessons Learned

### What Worked Well
- ✅ Pre-flight checks prevented lockouts
- ✅ Modular task structure (include_tasks) for clarity
- ✅ Configuration validation before applying changes
- ✅ Comprehensive variable defaults with sensible values
- ✅ Fail2ban provides immediate intrusion prevention

### Challenges Encountered
- ⚠️ Service name differences (sshd vs ssh) between distros
- ⚠️ Fail2ban log path varies (auth.log vs secure)
- ⚠️ Must handle both apt and dnf package managers

### Design Decisions
- **Why key-only auth?** Password brute-force is Red Team's first attack
- **Why fail2ban?** Automatic response to attacks without manual intervention
- **Why change root shell?** Defense in depth - even if SSH misconfigured, root can't login
- **Why strong crypto?** Prevent MitM attacks and cryptographic weaknesses

---

## 🚀 Next Steps: Firewall Configuration

**Focus:** Configure ufw (Ubuntu) and firewalld (Fedora) to allow only scored services

**Planned Deliverables:**
1. `roles/firewall/` - Firewall hardening role
2. `playbooks/05-firewall-hardening.yml` - Firewall playbook
3. Service-specific rules (HTTP, HTTPS, SMTP, POP3, FTP, DNS)
4. Red Team blocking patterns
5. Integration with scoring engine IP ranges

**Priority:**
- Allow scored services (from competition PDF)
- Block all other inbound traffic
- Rate limiting for web services
- Logging for intrusion detection

---

## 📸 VM Snapshots

**Created:**
- "Pre-SSH-Hardening" (before running playbook)
- "Post-SSH-Hardening" (after successful hardening)

**Rollback procedure if locked out:**
```
VMware → VM → Snapshot → Revert to "Pre-SSH-Hardening"
Then:
1. Verify SSH keys: ansible VM -m command -a "ls -la ~/.ssh/authorized_keys"
2. Re-deploy if missing: ./scripts/setup-ssh-keys.sh
3. Re-run: ansible-playbook playbooks/04-ssh-hardening.yml --limit VM
```

---

## ✅ Sprint 3.1 (SSH) Completion Criteria

- [x] SSH hardening role created with all task files
- [x] Fail2ban integration complete
- [x] Pre-flight checks prevent lockouts
- [x] Post-hardening validation confirms success
- [x] Playbook runs successfully on both VMs
- [x] Documentation complete (role README + sprint docs)
- [x] VM snapshots created
- [ ] Committed to `v2-rebuild` branch (do this next!)

**Sprint 3.1 Status: READY TO COMMIT ✅**

---

## 📝 Quick Reference: Common Tasks

### Test SSH Hardening on Single Host

```bash
ansible-playbook playbooks/04-ssh-hardening.yml --limit ubuntu_ecom_vm
```

### Skip Fail2ban Installation

```bash
ansible-playbook playbooks/04-ssh-hardening.yml \
  -e "ssh_hardening_enable_fail2ban=false"
```

### Check Configuration Applied

```bash
# View current SSH config
ansible all -m command -a "cat /etc/ssh/sshd_config" -b

# Check fail2ban status
ansible all -m command -a "fail2ban-client status sshd" -b

# View fail2ban logs
ansible all -m command -a "journalctl -u fail2ban -n 50" -b
```

### Rollback to Default SSH Config

```bash
# Find backup
ansible HOST -m shell -a "ls -lt /etc/ssh/sshd_config.backup.* | head -1" -b

# Restore backup
ansible HOST -m copy -a \
  "src=/etc/ssh/sshd_config.backup.XXXXX \
   dest=/etc/ssh/sshd_config \
   remote_src=yes" -b

# Restart SSH
ansible HOST -m systemd -a "name=sshd state=restarted" -b
```

---

## ⚠️ Troubleshooting

### Problem: Playbook fails on "Verify SSH keys on target"

**Cause:** SSH keys not deployed to target host

**Fix:**
```bash
# Deploy SSH keys
./scripts/setup-ssh-keys.sh

# Verify
ansible all -m command -a "ls -la ~/.ssh/authorized_keys"

# Re-run hardening
ansible-playbook playbooks/04-ssh-hardening.yml
```

### Problem: Locked out after hardening

**Cause:** SSH keys missing or incorrect

**Fix:**
1. Revert VM to "Pre-SSH-Hardening" snapshot
2. Verify keys: `ssh-add -l`
3. Re-deploy: `./scripts/setup-ssh-keys.sh`
4. Test manually: `ssh -i ~/.ssh/ccdc_rsa sysadmin@HOST`
5. Re-run hardening: `ansible-playbook playbooks/04-ssh-hardening.yml`

### Problem: Fail2ban won't start

**Cause:** iptables conflicts or missing dependencies

**Fix:**
```bash
# Check logs
ansible HOST -m command -a "journalctl -u fail2ban -n 100" -b

# Restart service
ansible HOST -m systemd -a "name=fail2ban state=restarted" -b

# Verify iptables rules
ansible HOST -m command -a "iptables -L -n" -b
```

### Problem: SSH config syntax error

**Cause:** Invalid sshd_config after modifications

**Fix:**
```bash
# Test config
ansible HOST -m command -a "/usr/sbin/sshd -t" -b

# View error details
ansible HOST -m command -a "/usr/sbin/sshd -T" -b

# Restore backup and restart
ansible HOST -m copy -a "src=/etc/ssh/sshd_config.backup.XXXXX dest=/etc/ssh/sshd_config remote_src=yes" -b
ansible HOST -m systemd -a "name=sshd state=restarted" -b
```

---

## 🎬 Git Commit Message Template

```
Sprint 3.1: SSH Hardening Complete

Deliverables:
- Created comprehensive SSH hardening role
  • Root account hardening (shell, login, password lock)
  • SSH configuration (key-only auth, strong crypto)
  • Fail2ban integration (intrusion prevention)
  • Pre-flight checks and validation
- Created playbook: 04-ssh-hardening.yml
- Documented role usage and troubleshooting

Security Improvements:
- Root SSH login: DISABLED
- Password authentication: DISABLED
- Fail2ban: ACTIVE
- Strong ciphers/MACs/KEX: ENFORCED

Testing:
- Dry run: ✅ No errors
- Single host: ✅ ubuntu_ecom_vm hardened
- All hosts: ✅ 2/2 successful
- Validation: ✅ All checks passed
- Connectivity: ✅ SSH key auth works

Next: Sprint 3.2 - Firewall Configuration (ufw/firewalld)
```

---

## 📚 Additional Resources

- [SSH Hardening Best Practices](https://www.ssh.com/academy/ssh/security)
- [Fail2ban Documentation](https://github.com/fail2ban/fail2ban/wiki)
- [OpenSSH Security](https://www.openssh.com/security.html)
- [NIST SSH Guidelines](https://nvlpubs.nist.gov/nistpubs/ir/2015/NIST.IR.7966.pdf)

---

## 🎉 Ready for Sprint 3.2!

All SSH hardening deliverables complete:
- ✅ Role structure implemented
- ✅ Security controls applied
- ✅ Testing validated
- ✅ Documentation comprehensive

**Use this prompt for Sprint 3.2:**

```
I've completed SSH hardening (Sprint 3.1). Ready to build the firewall configuration role next.

Current state:
- SSH hardening role working on 2 VMs
- Root login disabled, key-only auth enforced
- Fail2ban active and monitoring

Competition requirements from PDF:
- HTTP (port 80)
- HTTPS (port 443)
- SMTP (port 25)
- POP3 (port 110)
- FTP (port 21)
- DNS (port 53)
- SSH (port 22) - already secured

Need to:
1. Create roles/firewall/ with tasks for ufw (Ubuntu) and firewalld (Fedora)
2. Allow only scored services from scoring engine IPs
3. Block all other inbound traffic
4. Rate limiting for web services
5. Logging for intrusion detection

Let's build the firewall role!
```
