# MWCCDC Competition Day Deployment Guide

## 🎯 Purpose
This guide provides step-by-step instructions for deploying the CCDC Ansible automation during the high-stress competition environment. Designed for **rapid execution** with **minimal decision-making** required.

---

## ⏰ Timeline Overview

| Time | Phase | Duration | Actions |
|------|-------|----------|---------|
| **T-30 to T-15** | Pre-Competition | 15 min | Final checks, team coordination |
| **T-15 to T+0** | Login & Verify | 15 min | NISE login, welcome inject |
| **T+0 to T+20** | Automated Deployment | 20 min | Run automation, monitor progress |
| **T+20 to T+30** | Manual Network Changes | 10 min | **CRITICAL:** Change network device passwords |
| **T+30 to T+40** | Validation & Monitoring | 10 min | Verify services, check alerts |
| **T+40+** | Operations & Defense | Ongoing | Respond to injects, monitor intrusions |

---

## 📋 Pre-Competition Checklist (T-30 to T-15)

### Before Competition Starts

**Verify Environment:**
```bash
# 1. Check you're in the right directory
cd ~/ccdc-ansible  # or wherever your repo lives
ls -la inventory.ini ansible.cfg  # Should see both files

# 2. Verify ansible installation
ansible --version
# Should show ansible-core 2.15+

# 3. Test vault password
ansible-vault view group_vars/all/vault.yml
# Should decrypt successfully and show discord_webhook_url

# 4. Quick connectivity test (if able before competition starts)
# (Skip if not allowed yet)
# ansible all -m ping --limit localhost
```

**Quick Reference Sheet:**
```bash
# Print or have open:
# - Network topology diagram (page 12 of team pack)
# - Default credentials list (printed from vaults)
# - This deployment guide
# - VyOS cheat sheet (for network manager)
```

---

## 🚀 Competition Start Sequence

## **Phase 1: Initial Access (T-15 to T+0)**

### Step 1: Join Zoom & Access NISE (T-15)
```
1. Join Zoom web conference (link from competition organizers)
2. Navigate to NISE portal:
   - Morning: ccdcadmin1.morainevalley.edu
   - Afternoon: ccdcadmin3.morainevalley.edu
3. Login credentials:
   - Username: team##a through team##h (one per team member)
   - Password: (provided by competition director)
```

### Step 2: Complete Welcome Inject (T-15 to T-10)
```
1. Click "INJECTS" tab in NISE
2. Find "Welcome" inject
3. Create simple PDF response:
   "Team ## ready to compete - [Your School Name]"
4. Submit via NISE
5. WAIT for drop flag notification
```

### ⚠️ **CRITICAL: DO NOT ACCESS STADIUM YET**

---

## **Phase 2: Drop Flag & Stadium Access (T+0)**

### Step 3: Stadium Login (Immediately after drop flag)
```
1. NISE will show "Drop Flag - Cyber Stadium access released"
2. Navigate to: ccdc.cit.morainevalley.edu
3. Login credentials:
   - Username: v##u1 through v##u8 (8 accounts per team)
   - Password: (initial stadium password from competition director)
4. Change stadium password when prompted
   ⚠️ WRITE IT DOWN - You'll need it all day
5. Click "ENTER LAB" to access competition network
```

---

## **Phase 3: Automated Baseline (T+0 to T+20)**

### Step 4: Start Automation (T+0 - First 2 minutes)

```bash
sudo apt update
sudo apt install -y git

git clone https://www.github.com/BigDaddySkySky/ansible-ccdc.git
cd ansible-ccdc
./scripts/bootstrap.sh
```

**Ansible Operator executes:**

```bash
# Navigate to repo
cd ~/ccdc-ansible

# Activate venv if using one
source .venv/bin/activate  # Optional

# Start timer
date

# Launch full automation
ansible-playbook playbooks/run_all.yml

# Expected runtime: 15-20 minutes
```

**What run_all.yml does:**
1. ✅ Pre-checks (connectivity)
2. ✅ Baseline (backups, updates, firewall)
3. ✅ Hardening (disable services, enable logging)
4. ✅ Password reset (automated for Linux/Windows)
5. ✅ Intrusion detection deployment
6. ✅ Service validation

### Step 5: Monitor Progress (T+0 to T+20)

**Watch for:**
- Green "[OK]" messages for successful tasks
- Yellow "[CHANGED]" for configuration updates  
- Red "[FAILED]" for errors (see troubleshooting section)

**Common output to expect:**
```
PLAY [Pre-Competition Checks] ************
TASK [Ping Linux hosts] ******************
ok: [ubuntu_ecom]
ok: [fedora_webmail]
ok: [splunk]

PLAY [Baseline Configuration] ************
TASK [Create backup directory] ***********
changed: [ubuntu_ecom]
...

PLAY [System Hardening] ******************
...

PLAY [Deploy Intrusion Detection] ********
...
```

**If automation fails:**
```bash
# Option 1: Re-run just the failed section
ansible-playbook playbooks/baseline.yml  # If baseline failed
ansible-playbook playbooks/hardening.yml  # If hardening failed

# Option 2: Run on specific host
ansible-playbook playbooks/run_all.yml --limit ubuntu_ecom

# Option 3: Skip problematic sections
ansible-playbook playbooks/run_all.yml --skip-tags slow
```

---

## **Phase 4: CRITICAL Manual Tasks (T+20 to T+30)**

## ⚠️ **THIS CANNOT BE AUTOMATED - MUST BE DONE MANUALLY**

### Step 6: Network Device Password Changes

**Network Device Manager executes these immediately after automation completes:**

#### **Palo Alto Firewall:**
```
1. Access from Ubuntu workstation browser:
   URL: https://172.20.242.150

2. Login:
   Username: admin
   Current Password: Changeme123

3. Change password:
   Device → Administrators → admin → Change Password
   New Password: CompPalo2025!Secure
   Confirm and Commit

4. Test new login immediately
```

#### **Cisco FTD Firewall:**
```
1. Access from Windows 11 workstation browser:
   URL: https://172.20.102.254/#/login

2. Login:
   Username: admin
   Current Password: !Changeme123

3. Change password:
   Configuration → Users → admin → Edit
   New Password: CompCisco2025!Secure
   Save and Deploy

4. Test new login immediately
```

#### **VyOS Router:**
```
1. SSH from any workstation:
   ssh vyos@172.31.21.2
   Current Password: changeme

2. Change password:
   configure
   set system login user vyos authentication plaintext-password
   Enter new password: CompVyos2025!Secure
   commit
   save
   exit

3. Test new login:
   exit
   ssh vyos@172.31.21.2
   (login with new password)
```

### Step 7: Update Ansible Vaults (T+25)

**Ansible Operator must update vaults with new network device passwords:**

```bash
# Edit network device vault
ansible-vault edit group_vars/network_devices/vault.yml

# Update these values:
vault_paloalto_password: "CompPalo2025!Secure"
vault_cisco_ftd_password: "CompCisco2025!Secure"
vault_vyos_password: "CompVyos2025!Secure"

# Save and exit (ESC, :wq in vim)

# Verify changes saved
ansible-vault view group_vars/network_devices/vault.yml | grep password
```

**⚠️ WHY THIS MATTERS:**
- If you need to re-run automation later, it will use vaulted passwords
- Incident response playbooks may need network device access
- AD password resets reference these credentials

---

## **Phase 5: Validation (T+30 to T+40)**

### Step 8: Verify Services

```bash
# Quick service check
ansible-playbook playbooks/scoring_validation.yml

# Expected output:
# - SSH: ✅ Running
# - HTTP/HTTPS: ✅ Responding  
# - SMTP/POP3: ✅ Accessible
# - DNS: ✅ Resolving
# - FTP: ✅ Listening
```

### Step 9: Check Intrusion Detection

```bash
# Verify detection services running
ansible linux -m shell -a "systemctl is-active ccdc-log-watcher ccdc-honeypot-watcher" -o

# Expected: active for both services on each host

# Test Discord alerts (optional)
ansible-playbook playbooks/test_alerts.yml --tags critical --limit ubuntu_ecom
# Check Discord channel for test message
```

### Step 10: Verify NISE Service Status

```
1. Open NISE portal
2. Click "SERVICES" tab
3. Confirm all services show GREEN/UP:
   - HTTP (ubuntu_ecom, fedora_webmail, web01)
   - HTTPS (ubuntu_ecom, fedora_webmail, web01)
   - SSH (all Linux hosts)
   - SMTP/POP3 (fedora_webmail)
   - FTP (ftp01)
   - DNS (dc01)
   - RDP (Windows hosts)
```

---

## **Phase 6: Ongoing Operations (T+40+)**

### Monitor for Intrusions

**Discord Channel:**
- Watch for critical alerts: 🚨
- Respond to warnings: ⚠️
- Review info messages: ℹ️

**Manual Checks (every 15-30 minutes):**
```bash
# Re-run service validation
ansible-playbook playbooks/scoring_validation.yml

# Check for suspicious activity
ansible linux -m shell -a "tail -20 /var/log/ccdc/log_watcher.log" -o

# Review failed logins
ansible linux -m shell -a "tail -30 /var/log/auth.log | grep Failed" -o
```

### Respond to Injects

**NISE Inject Workflow:**
```
1. Check NISE "INJECTS" tab frequently
2. Read inject requirements carefully
3. Create response (usually PDF)
4. Submit before deadline
5. Mark inject as complete in your notes
```

**Common inject types:**
- Add/remove users
- Install software  
- Modify firewall rules
- Generate reports
- Investigate incidents
- Change configurations

**Use Ansible when possible:**
```bash
# Example: Add user inject
ansible ubuntu_ecom -m user -a "name=newuser state=present" --become

# Example: Install package inject
ansible fedora_webmail -m dnf -a "name=httpd-tools state=present" --become

# Example: Collect logs inject
ansible-playbook playbooks/incident_response.yml --limit ubuntu_ecom
```

### Handle Incidents

**If Red Team activity detected:**
```bash
# 1. Collect evidence immediately
ansible-playbook playbooks/incident_response.yml --limit <affected_host>

# 2. Review collected evidence
ls -lh incidents/<affected_host>/

# 3. Document in incident report (for inject submission)
cat incidents/<affected_host>/auth.log

# 4. Take corrective action as needed
```

**Quick incident response commands:**
```bash
# Kill suspicious process
ansible <host> -m shell -a "pkill -9 nc" --become

# Block IP address
ansible <host> -m shell -a "ufw deny from 10.X.X.X" --become

# Reset user password
ansible <host> -m user -a "name=<user> password={{ 'newpass' | password_hash('sha512') }}" --become
```

---

## 🛠️ Troubleshooting Guide

### Issue: Ansible playbook hangs

**Symptoms:** Playbook stuck on a task for >2 minutes

**Solutions:**
```bash
# 1. Cancel with Ctrl+C
# 2. Check what's hanging
ansible-playbook playbooks/baseline.yml -vvv --step

# 3. Skip the problematic task
ansible-playbook playbooks/baseline.yml --start-at-task="Task Name"

# 4. Run on subset of hosts
ansible-playbook playbooks/baseline.yml --limit "linux:!ubuntu_wks"
```

### Issue: Vault password errors

**Symptoms:** "Decryption failed" or "vault password file not found"

**Solutions:**
```bash
# Verify vault file exists
ls -la ~/.vault_pass

# Test decryption manually
ansible-vault view group_vars/all/vault.yml

# If file missing, create it:
echo "your_vault_password" > ~/.vault_pass
chmod 600 ~/.vault_pass
```

### Issue: Host unreachable

**Symptoms:** "unreachable" or "SSH connection failed"

**Solutions:**
```bash
# 1. Test connectivity manually
ping <host_ip>
ssh sysadmin@<host_ip>

# 2. Check inventory has correct IPs
cat inventory.ini | grep <hostname>

# 3. Verify SSH password hasn't changed
ansible-vault view group_vars/linux/vault.yml

# 4. Skip unreachable host temporarily
ansible-playbook playbooks/baseline.yml --limit "linux:!problem_host"
```

### Issue: Services showing as down in NISE

**Symptoms:** Red/down status in NISE "SERVICES" tab

**Solutions:**
```bash
# 1. Check service status directly
ansible <host> -m shell -a "systemctl status apache2" --become

# 2. Restart the service
ansible <host> -m service -a "name=apache2 state=restarted" --become

# 3. Check firewall
ansible <host> -m shell -a "ufw status" --become
ansible <host> -m shell -a "ss -tlnp | grep :80" --become

# 4. Review logs
ansible <host> -m shell -a "tail -50 /var/log/apache2/error.log" --become
```

### Issue: Package updates running too long

**Symptoms:** Baseline playbook stuck on "Update packages"

**Solutions:**
```bash
# 1. Let it run - updates can take 10-15 minutes
# 2. Monitor progress on host directly:
ssh sysadmin@<host>
sudo tail -f /var/log/apt/term.log  # Debian
sudo tail -f /var/log/dnf.log       # RedHat

# 3. If truly stuck, cancel and skip updates:
ansible-playbook playbooks/baseline.yml --skip-tags updates
```

### Issue: Intrusion detection not alerting

**Symptoms:** No Discord alerts appearing

**Solutions:**
```bash
# 1. Check webhook URL is configured
ansible-vault view group_vars/all/vault.yml | grep discord

# 2. Test webhook manually
ansible-playbook playbooks/test_alerts.yml --tags critical

# 3. Check detection services running
ansible linux -m shell -a "systemctl status ccdc-log-watcher" -o

# 4. Review detection logs
ansible linux -m shell -a "tail -50 /var/log/ccdc/log_watcher.log" -o

# 5. Restart detection services
ansible linux -m systemd -a "name=ccdc-log-watcher state=restarted" --become
ansible linux -m systemd -a "name=ccdc-honeypot-watcher state=restarted" --become
```

### Issue: Windows hosts not responding

**Symptoms:** WinRM errors, Windows playbooks failing

**Solutions:**
```bash
# 1. Verify WinRM from Windows side (via NETLAB console)
# Login to Windows host console:
Test-WSMan localhost
Get-Service WinRM

# 2. Check inventory settings
cat inventory.ini | grep -A5 "\[windows\]"

# 3. Test WinRM connectivity
ansible windows -m win_ping -vvv

# 4. If all else fails, make Windows changes manually
# via RDP or NETLAB console
```

---

## 📊 Quick Command Reference

### Monitoring Commands
```bash
# Check all services status
ansible-playbook playbooks/scoring_validation.yml -o

# Verify intrusion detection running
ansible linux -m shell -a "systemctl is-active ccdc-*" -o

# Check recent intrusion alerts
ansible linux -m shell -a "tail -20 /var/log/ccdc/*.log" -o

# View Discord alert queue status
ansible linux -m shell -a "ls -lh /var/spool/ccdc_alerts/" -o

# Test connectivity to all hosts
ansible all -m ping -o
```

### Emergency Commands
```bash
# Kill all automation (if something went wrong)
# Press Ctrl+C (may need multiple times)

# Re-run just baseline on one host
ansible-playbook playbooks/baseline.yml --limit ubuntu_ecom

# Quick firewall reset (if you locked yourself out)
ansible <host> -m shell -a "ufw disable && ufw --force enable && ufw allow 22" --become

# Emergency service restart
ansible <host> -m service -a "name=<service> state=restarted" --become

# Force password reset on single host
ansible-playbook playbooks/pass_reset.yml --limit <host> -e "force_reset=true"

# Collect incident evidence NOW
ansible-playbook playbooks/incident_response.yml --limit <host>
```

### Status Checks
```bash
# NISE service status (check in web browser)
# Navigate to: SERVICES tab in NISE portal

# Check package updates still running
ansible linux -m shell -a "ps aux | grep -E 'apt|dnf' | grep -v grep" -o

# Verify SSH access to all hosts
ansible all -m shell -a "hostname" -o

# Check disk space (important for logs)
ansible all -m shell -a "df -h / | tail -1" -o

# Check system load
ansible linux -m shell -a "uptime" -o
```

---

## 📝 Pre-Printed Checklists

### ✅ Competition Start Checklist

Print this and check off as you go:

```
□ T-15: Joined Zoom web conference
□ T-15: Logged into NISE portal (team##a through team##h)
□ T-15: Submitted "Welcome" inject
□ T-10: Confirmed all 8 team members have NISE access
□ T-5: Ansible laptop ready (verified vault password)
□ T-5: Network device credentials printed or accessible
□ T+0: Received "Drop Flag" notification in NISE
□ T+0: All team members logged into Stadium (v##u1-8)
□ T+0: Changed Stadium passwords (WROTE THEM DOWN)
□ T+0: Stadium topology visible
□ T+2: Started ansible-playbook playbooks/run_all.yml
□ T+2: Assigned someone to watch Ansible progress
□ T+2: Assigned someone to monitor NISE for new injects
□ T+20: Automation completed successfully
□ T+20: Verified no RED [FAILED] tasks in output
□ T+22: Changed Palo Alto password (CompPalo2025!Secure)
□ T+24: Changed Cisco FTD password (CompCisco2025!Secure)
□ T+26: Changed VyOS password (CompVyos2025!Secure)
□ T+28: Tested all 3 network device logins with new passwords
□ T+30: Updated Ansible vaults with new network passwords
□ T+35: Ran scoring_validation.yml successfully
□ T+40: Checked NISE - all services GREEN
□ T+40: Verified Discord alerts working (test_alerts.yml)
□ Ongoing: Monitoring for Red Team activity
□ Ongoing: Checking NISE for new injects every 10 minutes
```

### ✅ Network Device Password Checklist

Print this for Network Device Manager:

```
PALO ALTO (PA01)
□ URL: https://172.20.242.150
□ Login: admin / Changeme123
□ Change to: CompPalo2025!Secure
□ Location: Device → Administrators → admin → Change Password
□ Commit changes
□ Test new login: □ SUCCESS / □ FAILED
□ Wrote new password in secure location: □ YES

CISCO FTD (FTD01)
□ URL: https://172.20.102.254/#/login
□ Login: admin / !Changeme123
□ Change to: CompCisco2025!Secure
□ Location: Configuration → Users → admin → Edit
□ Deploy changes
□ Test new login: □ SUCCESS / □ FAILED
□ Wrote new password in secure location: □ YES

VYOS ROUTER
□ SSH: ssh vyos@172.31.21.2
□ Login: vyos / changeme
□ Command: configure
□ Command: set system login user vyos authentication plaintext-password
□ Enter: CompVyos2025!Secure
□ Command: commit
□ Command: save
□ Command: exit
□ Test new login: □ SUCCESS / □ FAILED
□ Wrote new password in secure location: □ YES

NOTIFY ANSIBLE OPERATOR:
□ Told Ansible operator to update vaults
□ Verified vaults updated (asked for confirmation)
```

---

## 🎯 Team Role Assignments

**Assign these roles BEFORE competition starts:**

### Ansible Operator
**Primary:** Run automation, respond to playbook errors  
**Secondary:** Monitor Linux hosts, handle SSH access

**Commands they'll use:**
- `ansible-playbook playbooks/run_all.yml`
- `ansible-playbook playbooks/scoring_validation.yml`
- `ansible-playbook playbooks/incident_response.yml`
- `ansible-vault edit group_vars/*/vault.yml`

### Network Device Manager  
**Primary:** Manual password changes on PA/FTD/VyOS  
**Secondary:** Monitor network connectivity, handle routing issues

**Access they'll need:**
- Ubuntu workstation (for PA web access)
- Windows 11 workstation (for FTD web access)
- SSH access to VyOS
- VyOS quick reference card

### Windows Administrator
**Primary:** Monitor Windows hosts, handle RDP access  
**Secondary:** Active Directory tasks, Windows-specific injects

**Access they'll need:**
- RDP to DC01, Web01, FTP01, Windows11_wks
- Administrator credentials (from vault)
- Windows quick reference commands

### Incident Responder
**Primary:** Monitor Discord alerts, respond to intrusions  
**Secondary:** Log analysis, evidence collection

**Commands they'll use:**
- `ansible-playbook playbooks/incident_response.yml`
- `ansible-playbook playbooks/check_intrusions.yml`
- Manual log review via SSH

### Inject Manager (CRITICAL ROLE)
**Primary:** Monitor NISE every 5-10 minutes for new injects  
**Secondary:** Coordinate inject responses, track deadlines

**Responsibilities:**
- Check NISE "INJECTS" tab constantly
- Read inject requirements aloud to team
- Track inject deadlines
- Ensure responses submitted on time
- Coordinate who handles each inject

**Tools they'll need:**
- NISE portal open at all times
- Spreadsheet or notepad for tracking
- Timer/alarm for inject deadlines

---

## ⚠️ Critical Mistakes to Avoid

### Don't Do These:

1. **❌ DON'T change IP addresses** (unless inject specifically says to)
   - Will break scoring
   - Will break Ansible connectivity
   - May violate competition rules

2. **❌ DON'T forget to `commit` and `save` on VyOS**
   - Changes are lost on reboot without `save`
   - Use: `commit` then `save` then `exit`

3. **❌ DON'T block ICMP (ping) completely**
   - Scoring engine needs this
   - Will lose points for service unavailability

4. **❌ DON'T update network device vaults with wrong passwords**
   - Double-check passwords match what you set
   - Test login before updating vault

5. **❌ DON'T run automation while services are being scored**
   - Could cause temporary service interruption
   - Wait for service checks to complete

6. **❌ DON'T ignore NISE inject notifications**
   - Injects have deadlines
   - Late submissions = 0 points
   - Missing injects loses 35-50% of total score

7. **❌ DON'T scan or attack other teams**
   - Instant disqualification
   - Applies to all offensive tools (nmap, metasploit, etc.)

8. **❌ DON'T disable auditd on RedHat systems**
   - Required for intrusion detection
   - Very hard to restart if stopped

9. **❌ DON'T commit plaintext vault files to git**
   - Always verify encrypted: `head -1 group_vars/*/vault.yml`
   - Should show: `$ANSIBLE_VAULT;1.2;AES256`

10. **❌ DON'T panic when Red Team gets access**
    - Collect evidence first (incident_response.yml)
    - Document what happened
    - Kick them out
    - Submit incident report inject

---

## 🚀 Competition Day Success Formula

### First 40 Minutes: Setup & Harden
```
T+0:   Start automation (20 min)
T+20:  Manual network passwords (10 min)
T+30:  Validation (10 min)
```

### Next 20 Minutes: Stabilize
```
T+40:  Fix any service issues
T+50:  Review first inject(s)
T+60:  Establish monitoring rhythm
```

### Remaining Time: Defend & Respond
```
Every 15 min:  Run scoring_validation.yml
Every 10 min:  Check NISE for new injects
Every 30 min:  Review Discord alerts
As needed:     Respond to incidents
```

### Key Success Factors:
1. ✅ **Speed in first 20 minutes** - Automation gives you huge advantage
2. ✅ **Don't forget network devices** - Manual changes are critical
3. ✅ **Monitor constantly** - Injects and intrusions happen fast
4. ✅ **Respond to injects first** - They're 35-50% of your score
5. ✅ **Document incidents** - Red Team compromise reports are worth points
6. ✅ **Stay calm** - You have automation, other teams don't

---

## 📞 Emergency Contacts

**During Competition:**
- White Team: Use NISE "HELP" feature or ask in Zoom chat
- Green Team (Tech Support): For NETLAB/Stadium issues
- Your Coach: Can observe but NOT assist with technical tasks

**Common Questions for White Team:**
- "Service X is down in NISE but responds to our checks - is scoring working?"
- "Can we get clarification on inject #X requirement?"
- "Red Team activity detected - how do we submit incident report?"
- "NETLAB VM is frozen - can we get a power cycle?"

---

## 🎓 Final Pre-Competition Advice

### Night Before:
- Get good sleep (seriously)
- Review this guide
- Print checklists
- Test Ansible connectivity (if allowed)
- Assign team roles

### Morning Of:
- Arrive 30 minutes early
- Have coffee/energy drinks ready
- Set up workspace (multiple monitors helpful)
- Have this guide open
- Have VyOS cheat sheet printed

### During Competition:
- **Breathe**
- Trust your automation
- Communicate constantly
- Don't second-guess the plan
- You've prepared for this

---

## 📚 Additional Resources

**In This Repo:**
- `README.md` - Full repository documentation
- `scripts/` - Helper scripts for common tasks
- `playbooks/` - All automation playbooks
- `vyos cheat sheet.md` - VyOS command reference
- `vyos quick reference.md` - VyOS one-pager

**Competition Docs:**
- Team Pack PDF (attached) - Full competition rules and topology
- NISE portal help section
- NETLAB help documentation

---

## 🏆 You've Got This!

Your team has prepared thoroughly. You have automation that other teams don't. Follow this guide, stay calm, and execute the plan. The first 40 minutes are critical - get through those successfully and you'll be in excellent shape for the rest of the competition.

**Remember:**
- Automation gives you a 20-minute head start
- Network device passwords MUST be changed manually (T+20)
- Injects are 35-50% of your score - don't ignore NISE
- Evidence collection is worth points - document Red Team activity
- Services must stay up - verify with scoring_validation.yml

**Good luck and dominate that competition! 🎯🛡️🚀**
