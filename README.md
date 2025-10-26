# CCDC 2025 Ansible Automation Repository

**Competition-ready Ansible automation for rapid baseline, hardening, and incident response**

---

## 🚀 Quick Start (Competition Day)

```bash
# 1. Activate virtual environment (if using)
source .venv/bin/activate

# 2. Install python dependencies
pip install -r requirements.txt

# 3. Install ansible dependencies
ansible-galaxy install -r requirements.yml

# 3. Ensure vault password is set
cat ~/.vault_pass
# Should contain your vault password

# 4. Test connectivity
ansible all -m ping

# Safe check command
ansible-playbook playbooks/run_all.yml --check

# 5. Run full baseline
ansible-playbook playbooks/run_all.yml

# Or run step-by-step:
ansible-playbook playbooks/baseline.yml
ansible-playbook playbooks/pass_reset.yml
ansible-playbook playbooks/hardening.yml
ansible-playbook playbooks/scoring_validation.yml
```

---

## 📁 Repository Structure
- Directories have been separated by intent for better organization. 
- Flat files include `linux.yml` and `windows.yml` to refrence vaults and high-level toggles
- Nested directories such as `group_vars/linux` and `group_vars/windows` are separated by concern (packages, services, features)
- `network_devices/` contains device-specific vars and top level `*.yml` are legacy references planned for consolidation.
    - Optionally migrate fully into `network_devices/` and remove top-level duplicates


```
.
├── ansible.cfg                 # Ansible configuration
├── inventory.ini              # All hosts and groups
├── requirements.yml           # Ansible collections
├── requirements.txt           # Python packages
│
├── group_vars/                # Host/group variables
│   ├── all/
│   │   ├── general.yml       # Global non-sensitive vars
│   │   └── ports.yml         # Port definitions
│   ├── linux/
│   │   ├── packages.yml      # Package lists
│   │   ├── services.yml      # Service definitions
│   │   └── vault.yml         # 🔒 ENCRYPTED Linux credentials
│   ├── windows/
│   │   ├── features.yml      # Windows features
│   │   └── vault.yml         # 🔒 ENCRYPTED Windows credentials
│   ├── network_devices/      # Network device configs
│   ├── web_servers/          # Web server configs
│   ├── linux.yml             # Linux vault references
│   ├── windows.yml           # Windows vault references
│   ├── paloalto.yml          # Palo Alto vars
│   ├── cisco_ftd.yml         # Cisco FTD vars
│   └── routers.yml           # VyOS vars
│
├── host_vars/
│   └── splunk.yml            # 🔒 ENCRYPTED Splunk-specific vars
│
├── playbooks/
│   ├── baseline.yml          # 🔥 FIRST 15 MIN - Critical setup
│   ├── pass_reset.yml        # 🔐 Password rotation
│   ├── hardening.yml         # Security hardening
│   ├── scoring_validation.yml # Service checks
│   ├── incident_response.yml # Evidence collection
│   ├── pre_check.yml         # Pre-competition validation
│   ├── run_all.yml           # 🎯 Master orchestration
│   ├── rollback.yml          # Emergency rollback
│   └── notify_team.yml       # Team notifications
│
└── roles/                    # Reusable task modules
    ├── common/               # Baseline tasks
    ├── firewall/             # Firewall configuration
    ├── hardening/            # Security hardening
    ├── incident_response/    # IR tasks
    └── web_server/           # Web server tasks
```

---

## 🎯 Competition Day Workflow

### T-15 Minutes: Pre-Competition
```bash
# Join Zoom web conference
# Login to NISE: ccdcadmin1 or ccdcadmin3.morainevalley.edu
# Team accounts: team##a through team##h
# Respond to "Welcome" inject
```

### T+00:00: Competition Starts (Drop Flag)
```bash
# 1. Access Competition Stadium: ccdc.cit.morainevalley.edu
#    Stadium accounts: v##u1 through v##u8
#    Change stadium password when prompted

# 2. Run full automation (15-20 minutes)
ansible-playbook playbooks/run_all.yml

# This runs:
# - pre_check.yml (validation)
# - baseline.yml (firewalls, updates, backups)
# - pass_reset.yml (automated password changes)
# - hardening.yml (disable services, enable logging)
# - scoring_validation.yml (verify services)
```

- **Fallback:** Run `pre_check.yml` -> `baseline.yml` -> `hardening.yml` individually to isolate failures.
- **Use --step:**
```bash
asnible-playbook playbooks/baseline.yml --step
```
- **Add async updates reminder (baseline):** Note that package updates may continue after baseline completes. Provide a quick check:
```bash
ps aux | grep -E 'apt|dnf|yum'
```

### T+00:18: Manual Password Changes (CRITICAL!)
After automated password reset completes, manually change network device passwords:

**Palo Alto Firewall:**
```
URL: https://172.20.242.150 (from Ubuntu workstation)
Current: admin / Changeme123
New: CompPalo2025!Secure
```

**Cisco FTD Firewall:**
```
URL: https://172.20.240.200 or https://172.20.102.254/#/login (from Win11 workstation)
Current: admin / !Changeme123
New: CompCisco2025!Secure
```

**VyOS Router:**
```bash
ssh vyos@172.31.21.2
# Current password: changeme
configure
set system login user vyos authentication plaintext-password
# Enter: CompVyos2025!Secure
commit
save
exit
```

** -- UPDATE VAULTS! -- **
```bash
# Updates vaults with new device credentials
ansible-vault edit group_vars/linux/vault.yml
ansible-vault edit group_vars/windows/vault.yml
ansible-vault edit group_vars/network_devices/vault.yml
```

### Ongoing: Monitor & Respond
```bash
# Run scoring validation every 15-30 minutes
ansible-playbook playbooks/scoring_validation.yml

# Monitor NISE for new injects
# Check Splunk: https://172.20.242.20:8000

# For incidents
ansible-playbook playbooks/incident_response.yml
```

---

## 📊 Network Topology

| Host | IP | OS | Services |
|------|----|----|----------|
| ubuntu_ecom | 172.20.242.104 | Ubuntu | HTTP/HTTPS |
| fedora_webmail | 172.20.242.101 | Fedora | HTTP/HTTPS, SMTP, POP3 |
| splunk | 172.20.242.20 | Linux | Splunk Enterprise (8000, 8089) |
| dc01 | 172.20.240.102 | Windows Server | DNS, Active Directory |
| web01 | 172.20.240.101 | Windows Server | HTTP/HTTPS |
| ftp01 | 172.20.240.104 | Windows Server | FTP |
| ubuntu_wks | DHCP | Ubuntu | Workstation |
| windows11_wks | 172.20.240.100 | Windows 11 | Workstation |
| paloalto | 172.20.242.150 | PAN-OS | Firewall |
| cisco_ftd | 172.20.240.200 | FTD | Firewall |
| vyos | 172.31.21.2 | VyOS | Router |

---

## 🔐 Default Credentials (Before Password Reset)

### Linux Systems (ubuntu_ecom, fedora_webmail, ubuntu_wks)
- SSH: sysadmin / changeme
- Root: changeme (via sudo)

### Splunk
- SSH: sysadmin / changemenow
- Web: admin / changemenow
- URL: https://172.20.242.20:8000

### Windows Systems
- Administrator: !Password123
- UserOne (Win11): ChangeMe123

### Network Devices
- Palo Alto: admin / Changeme123
- Cisco FTD: admin / !Changeme123
- VyOS: vyos / changeme

**⚠️ All default passwords are stored encrypted in vault files**

---

## 🔒 Vault Management

### Working with Encrypted Files

```bash
# View encrypted file
ansible-vault view group_vars/linux/vault.yml

# Edit encrypted file
ansible-vault edit group_vars/linux/vault.yml

# Encrypt a plaintext file
ansible-vault encrypt group_vars/linux/vault.yml

# Decrypt a file (for editing outside vault)
ansible-vault decrypt group_vars/linux/vault.yml
# ... edit file ...
ansible-vault encrypt group_vars/linux/vault.yml

# Change vault password
ansible-vault rekey group_vars/linux/vault.yml
```

### Vault Password Location
- Stored in: `~/.vault_pass`
- Referenced in: `ansible.cfg`
- **NEVER commit `.vault_pass` to git!**

---

## 🎓 Playbook Details

### baseline.yml (15-20 minutes)
**Purpose:** Critical first 15 minutes setup
- Creates `/root/ccdc_backup/` with `/etc` archive
- Enables UFW/firewalld with default-deny
- Opens only required ports (SSH, HTTP/S, SMTP, FTP, RDP, WinRM)
- Starts package updates in background (async)
- Runs firewall role

### pass_reset.yml (3-5 minutes)
**Purpose:** Rotate all default passwords
- Resets sysadmin and root on Linux
- Resets Administrator and UserOne on Windows
- Resets Splunk admin password
- Displays manual instructions for network devices

### hardening.yml (5-10 minutes)
**Purpose:** Reduce attack surface
- Disables unnecessary services (cups, avahi-daemon, bluetooth)
- Enables auditd logging
- Uses hardening role

### scoring_validation.yml (2-3 minutes)
**Purpose:** Verify services are accessible
- Checks HTTP/HTTPS on web servers
- Checks SMTP/POP3 on mail servers
- Checks DNS resolution
- Checks FTP accessibility
- Checks SSH/RDP connectivity

### incident_response.yml (3-5 minutes)
**Purpose:** Collect evidence of Red Team activity
- Fetches auth.log and secure logs
- Scans for suspicious processes (nc, ncat, socat, reverse shells)
- Saves to `./incidents/[hostname]/`

### run_all.yml (20-25 minutes)
**Purpose:** Master orchestration
- Runs all playbooks in correct order
- Can skip sections with tags
- Example: `ansible-playbook playbooks/run_all.yml --skip-tags pre_check`

---

## 🏆 Scoring Breakdown

- **35-50%** - Service uptime (HTTP, HTTPS, SMTP, POP3, FTP, DNS)
- **35-50%** - Inject completion (business tasks)
- **10-20%** - Incident response & Red Team defense

**Win Condition:** Highest total score

---

## 🛠️ Troubleshooting

- ansible-config verification:
```bash
ansible-config dump | grep -E 'DEFAULT_HOST_LIST|DEFAULT_VAULT_PASSWORD_FILE|INTERPRETER_PYTHON'

### Connection Issues
```bash
# Test specific host
ansible ubuntu_ecom -m ping -vvv

# Test SSH manually
ssh sysadmin@172.20.242.104

# Test WinRM
ansible windows11_wks -m win_ping -vvv
```

### Service Down
```bash
# Check service status
ansible web_servers -m shell -a "systemctl status apache2" --become

# Restart service
ansible fedora_webmail -m shell -a "systemctl restart httpd" --become

# Check firewall
ansible linux -m shell -a "ufw status" --become
```

### Playbook Errors
```bash
# Run with verbose output
ansible-playbook playbooks/baseline.yml -vvv

# Check ansible.log
tail -50 ansible.log

# Run specific tags only
ansible-playbook playbooks/baseline.yml --tags firewall

# Skip slow tasks
ansible-playbook playbooks/baseline.yml --skip-tags slow

# Limit to specific host
ansible-playbook playbooks/baseline.yml --limit ubuntu_ecom

# Sanity check vaulted passwords
ansible-vault view group_vars/linux/vault.yml

# Combine `limit` and `tags`
ansible-playbook playbooks/baseline.yml --limit ubuntu_ecom -tags firewall -vvv
```
---

## 🚫 Competition Rules - Remember!

### ❌ PROHIBITED
- No changing system names or IP addresses (unless inject says so)
- No offensive actions against other teams
- No restricting services by source IP (breaks scoring)
- No USB drives, unauthorized devices in competition area
- No free trial software (only free/open source)

### ✅ ALLOWED
- Replace services (e.g., Apache → Nginx) if functionality maintained
- Change all passwords
- Install free/open source software
- Reconfigure servers and networking equipment

### ⚠️ REQUIRED
- Maintain ICMP (ping) on all devices
- Keep services accessible from ALL source IPs
- Preserve pre-existing data when migrating services
- Submit incident reports for detected Red Team activity

---

## 📝 Pre-Competition Checklist

- [ ] Clone repo to competition machine
- [ ] Install Python 3.8+ and create virtualenv
- [ ] Install Ansible: `pip install ansible pywinrm`
- [ ] Install collections: `ansible-galaxy collection install -r requirements.yml`
- [ ] Create `~/.vault_pass` with vault password
- [ ] Verify all vault files are encrypted
- [ ] Update IP addresses in inventory if changed
- [ ] Set competition-specific passwords in vault files
- [ ] Run pre-check: `ansible-playbook playbooks/pre_check.yml`
- [ ] Print README and COMPETITION_CHEATSHEET
- [ ] Print vault passwords (securely!)

---

## 🎯 Quick Commands Reference

```bash
# Test connectivity
ansible all -m ping

# Run full baseline
ansible-playbook playbooks/run_all.yml

# Run only password reset
ansible-playbook playbooks/pass_reset.yml

# Check service status
ansible-playbook playbooks/scoring_validation.yml

# Collect incident evidence
ansible-playbook playbooks/incident_response.yml

# Run with tags
ansible-playbook playbooks/baseline.yml --tags firewall

# Skip sections
ansible-playbook playbooks/run_all.yml --skip-tags pre_check

# Limit to host
ansible-playbook playbooks/baseline.yml --limit splunk

# Verbose output
ansible-playbook playbooks/baseline.yml -vvv

# Check mode (dry run)
ansible-playbook playbooks/baseline.yml --check
```

---

## 📚 Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [CCDC Rules](https://www.nationalccdc.org/)
- [Competition Packet](https://www.caeepnc.org/mwccdc/)
- [Ansible Vault Guide](https://docs.ansible.com/ansible/latest/user_guide/vault.html)

---

**Good luck, Blue Team! 🛡️🚀**
