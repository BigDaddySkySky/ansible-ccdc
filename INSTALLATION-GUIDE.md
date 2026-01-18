# Sprint 3.1: SSH Hardening - Installation Guide

## 📦 What's Included

This package contains a complete SSH hardening role for your CCDC Ansible automation project:

```
roles/ssh_hardening/
├── tasks/
│   ├── main.yml              # Main orchestration
│   ├── preflight.yml         # Safety checks before hardening
│   ├── root_hardening.yml    # Root account security
│   ├── ssh_config.yml        # SSH daemon configuration
│   ├── fail2ban.yml          # Intrusion prevention
│   └── validate.yml          # Post-hardening validation
├── defaults/
│   └── main.yml              # 50+ configurable variables
├── handlers/
│   └── main.yml              # Service restart handlers
├── templates/
│   └── jail.local.j2         # Fail2ban configuration template
├── meta/
│   └── main.yml              # Role metadata
└── README.md                 # Complete documentation

playbooks/
└── 04-ssh-hardening.yml      # Ready-to-run playbook

docs/
└── SPRINT-3.md               # Sprint documentation
```

## 🚀 Installation

### Step 1: Copy Files to Your Project

```bash
# Navigate to your ansible-ccdc-v2 directory
cd ~/ccdc-testing/ansible-ccdc-v2

# Copy the roles directory
cp -r /path/to/downloaded/roles ./

# Copy the playbook
cp /path/to/downloaded/04-ssh-hardening.yml ./playbooks/

# Copy the documentation
cp /path/to/downloaded/SPRINT-3.md ./docs/
```

### Step 2: Verify File Structure

```bash
# Check that files are in place
ls -la roles/ssh_hardening/tasks/
ls -la playbooks/04-ssh-hardening.yml
ls -la docs/SPRINT-3.md
```

### Step 3: Review Role Variables

```bash
# View default configuration
cat roles/ssh_hardening/defaults/main.yml

# Customize if needed (optional)
# Edit group_vars/all/ or host_vars/ to override defaults
```

## ✅ Prerequisites

Before running the SSH hardening playbook:

### 1. SSH Keys Must Be Deployed

```bash
# Deploy SSH keys to all VMs
./scripts/setup-ssh-keys.sh

# Verify keys are in place
ansible all -m command -a "ls -la ~/.ssh/authorized_keys"
```

### 2. Create VM Snapshots in your practice environment

```
VMware Workstation:
1. Right-click VM
2. Snapshot → Take Snapshot
3. Name: "Pre-SSH-Hardening"
4. Repeat for all VMs
```

### 3. Verify Connectivity

```bash
# Validate basic connectivity
ansible-playbook playbooks/00-hello-world.yml

# Validate environment
ansible-playbook playbooks/01-validate-environment.yml
```

## 🧪 Validation

### Validate on Single Host First

```bash
# Dry run (see what would change)
ansible-playbook playbooks/04-ssh-hardening.yml --check

# Apply to one VM
ansible-playbook playbooks/04-ssh-hardening.yml --limit ubuntu_ecom_vm

# Verify SSH still works
ssh -i ~/.ssh/ccdc_rsa sysadmin@192.168.1.250
```

### Apply to All Hosts

```bash
# Run on all VMs
ansible-playbook playbooks/04-ssh-hardening.yml

# Verify connectivity
ansible all -m ping
```

## 🔍 Validation

After running the playbook, verify the hardening was applied:

```bash
# Check root shell
ansible all -m command -a "getent passwd root | cut -d: -f7" -b
# Expected: /bin/nologin

# Verify password auth disabled
grep "^PasswordAuthentication no" /etc/ssh/sshd_config

# Check fail2ban status
ansible all -m command -a "fail2ban-client status sshd" -b

# Test SSH access
ssh -i ~/.ssh/ccdc_rsa sysadmin@192.168.1.250
# Should work with keys

# Test password auth (should fail)
ssh sysadmin@192.168.1.250
# Expected: Permission denied (publickey)
```

## 🛡️ What This Role Does

### Security Controls Applied

1. **Root Account Hardening:**
   - Root SSH login disabled (`PermitRootLogin no`)
   - Root shell changed to `/bin/nologin`
   - Root account password locked

2. **SSH Authentication:**
   - Password authentication disabled (`PasswordAuthentication no`)
   - Public key authentication enforced
   - Empty passwords forbidden
   - Max 3 authentication attempts

3. **Cryptographic Hardening:**
   - Strong ciphers only (chacha20-poly1305, aes256-gcm, aes256-ctr)
   - Strong MACs (hmac-sha2-512-etm, hmac-sha2-256-etm)
   - Strong KEX algorithms (curve25519-sha256, diffie-hellman-group-exchange-sha256)

4. **Fail2ban Integration:**
   - Automatic IP banning after 3 failed attempts
   - 10-minute ban duration
   - iptables integration

## ⚙️ Configuration

### Override Default Variables

Create `group_vars/linux_servers/ssh_hardening.yml`:

```yaml
---
# Custom SSH hardening settings
ssh_hardening_fail2ban_bantime: 3600  # 1 hour instead of 10 minutes
ssh_hardening_max_auth_tries: 2       # 2 attempts instead of 3

# Disable fail2ban if not needed
ssh_hardening_enable_fail2ban: false
```

### Per-Host Configuration

Create `host_vars/ubuntu_ecom_vm/ssh_hardening.yml`:

```yaml
---
# Host-specific SSH settings
ssh_hardening_max_auth_tries: 5  # Allow more attempts on this host
```

## 🐛 Troubleshooting

### Locked Out After Hardening?

**Immediate Fix:**
1. Revert VM to "Pre-SSH-Hardening" snapshot
2. Verify SSH keys: `ansible HOST -m command -a "ls -la ~/.ssh/authorized_keys"`
3. Re-deploy keys: `./scripts/setup-ssh-keys.sh`
4. Re-run hardening: `ansible-playbook playbooks/04-ssh-hardening.yml --limit HOST`

### Fail2ban Won't Start?

```bash
# Check logs
ansible HOST -m command -a "journalctl -u fail2ban -n 100" -b

# Restart service
ansible HOST -m systemd -a "name=fail2ban state=restarted" -b

# Check iptables rules
ansible HOST -m command -a "iptables -L -n" -b
```

### SSH Config Syntax Error?

```bash
# Test config
ansible HOST -m command -a "/usr/sbin/sshd -t" -b

# Restore backup
ansible HOST -m shell -a "ls -lt /etc/ssh/sshd_config.backup.* | head -1" -b
# Note the backup filename, then:
ansible HOST -m copy -a "src=/etc/ssh/sshd_config.backup.XXXXX dest=/etc/ssh/sshd_config remote_src=yes" -b

# Restart SSH
ansible HOST -m systemd -a "name=sshd state=restarted" -b
```

## 📝 Git Workflow

### Commit the Changes

```bash
# Add all files
git add roles/ssh_hardening/
git add playbooks/04-ssh-hardening.yml
git add docs/SPRINT-3.md

# Commit
git commit -m "Sprint 3.1: SSH hardening role complete

- Created comprehensive SSH hardening role
- Root account hardening (shell, login, password lock)
- SSH configuration (key-only auth, strong crypto)
- Fail2ban integration for intrusion prevention
- Pre-flight checks and validation
- Created playbook: 04-ssh-hardening.yml
- Tested on 2 VMs: ubuntu_ecom_vm, fedora_webmail_vm"

# Push to GitHub
git push origin v2-rebuild
```

## 🎯 Next Steps

After SSH hardening is complete:

1. **Create Post-Hardening Snapshots:**
   ```
   VMware → Snapshot → "Post-SSH-Hardening"
   ```

2. **Document Passwords:**
   - Update password manager with rotated credentials
   - Document which hosts have which passwords

3. **Continue Sprint 3:**
   - Sprint 3.2: Firewall configuration (ufw/firewalld)
   - Sprint 3.3: Auditd monitoring
   - Sprint 3.4: Discord webhook alerts

## 📚 Additional Documentation

- **Role Documentation:** `roles/ssh_hardening/README.md`
- **Sprint Documentation:** `docs/SPRINT-3.md`
- **Validation Guide:** See "Validation" section in SPRINT-3.md
- **Troubleshooting:** See SPRINT-3.md for detailed solutions

## 🎉 Success Criteria

You'll know Sprint 3.1 is complete when:

- ✅ SSH hardening role runs without errors
- ✅ All VMs accessible via SSH keys
- ✅ Root login disabled (expect `ssh root@HOST` to fail)
- ✅ Password auth disabled (expect `ssh sysadmin@HOST` to fail)
- ✅ Fail2ban running (`fail2ban-client status sshd`)
- ✅ VM snapshots created
- ✅ Changes committed to git

## 📞 Support

If you encounter issues:

1. Check the role README: `roles/ssh_hardening/README.md`
2. Review Sprint 3 docs: `docs/SPRINT-3.md`
3. Check Ansible logs: `ansible-playbook ... -vvv`
4. Revert to a snapshot in your practice environment and try again

## ⚠️ Important Notes

- **Always validate on snapshots in your practice environment first!** You cannot recover from lockout without snapshots during competition.
- **SSH keys are mandatory** before disabling password auth
- **Create backups** automatically before changes
- **Validate immediately** after hardening completes
- **Document everything** for your team

---

**Sprint 3.1 Status: READY TO DEPLOY ✅**

Follow the steps above to integrate this SSH hardening role into your CCDC automation!
