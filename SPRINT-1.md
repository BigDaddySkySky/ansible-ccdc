# Sprint 1: Inventory & Discovery

## 🎯 Sprint Goals

1. **Establish baseline inventory** with priority groupings
2. **Validate SSH connectivity** to all target hosts
3. **Discover services** running on each host
4. **Generate baseline reports** for comparison later
5. **Test cross-distro compatibility** (Ubuntu + Fedora)

---

## 📋 Deliverables

### ✅ Completed

- [x] Control node setup (Kali WSL)
- [x] 2 VMs created (Ubuntu 24.04 Ecom, Fedora 43 Webmail)
- [x] SSH connectivity validated (both hosts reachable)
- [x] `playbooks/00-hello-world.yml` - Basic connectivity test
- [x] `playbooks/01-validate-environment.yml` - Pre-flight checks
- [x] `playbooks/02-discover-hosts.yml` - Service discovery
- [x] Services installed on VMs (Apache, MySQL, Postfix, Dovecot)
- [x] Enhanced inventory with priority groups
- [x] Baseline reports generated

---

## 🧪 Testing & Validation

### Test 1: Connectivity
```bash
ansible-playbook playbooks/00-hello-world.yml
# Expected: 2/2 hosts reachable
```

### Test 2: Environment
```bash
ansible-playbook playbooks/01-validate-environment.yml
# Expected: Both hosts show "✅ READY"
```

### Test 3: Discovery
```bash
ansible-playbook playbooks/02-discover-hosts.yml
# Expected: Reports saved to /tmp/*_baseline.json
```

### Test 4: Priority Groups
```bash
# Test targeting specific groups
ansible web_servers -m ping
ansible mail_servers -m ping
ansible critical_services -m ping
```

### Test 5: Service Validation
```bash
# From Kali WSL
curl http://192.168.1.250  # Ubuntu Ecom - should return HTML
curl http://192.168.1.251  # Fedora Webmail - should return HTML
telnet 192.168.1.251 25    # Postfix SMTP - should connect
```

---

## 📊 Sprint Metrics

**VM Configuration:**
- Ubuntu 24.04 Ecom (192.168.1.250)
  - Services: Apache2, MySQL, SSH
  - Ports: 22, 80, 3306
  - Purpose: E-commerce server simulation
  
- Fedora 43 Webmail (192.168.1.251)
  - Services: Postfix, Dovecot, Apache, MariaDB, SSH
  - Ports: 22, 25, 80, 110, 143
  - Purpose: Webmail server simulation

**Inventory Groups:**
- `linux_servers`: All Linux targets (2 hosts)
- `critical_services`: Must-stay-up hosts (2 hosts)
- `web_servers`: HTTP/HTTPS services (2 hosts)
- `mail_servers`: SMTP/IMAP/POP3 services (1 host)
- `database_servers`: MySQL/MariaDB (2 hosts)

---

## 🎓 Lessons Learned

### What Worked Well
- ✅ Kali WSL → VMware connectivity seamless (bridged networking)
- ✅ Cross-distro testing caught Python version differences (3.12 vs 3.14)
- ✅ Priority groups enable flexible targeting
- ✅ Discovery playbook reveals security gaps before hardening

### Challenges Encountered
- ⚠️ Initial inventory summary calculation bug (non-blocking)
- ⚠️ Fedora firewall required explicit service rules
- ⚠️ Service installation required different package managers

### Improvements for Sprint 2
- Add vault management for credentials
- Create password rotation playbook
- Implement host-specific passwords (not shared)
- Add firewall hardening

---

## 🚀 Next Steps: Sprint 2

**Focus:** Secrets & Bootstrap Hardening

**Planned Deliverables:**
1. `group_vars/all/vault.yml` - Global secrets (Discord webhooks)
2. `host_vars/*/vault.yml` - Host-specific passwords
3. `playbooks/03-rotate-passwords.yml` - Change default credentials
4. `playbooks/04-baseline-hardening.yml` - Basic SSH/firewall security
5. Enhanced bootstrap with vault validation

**Priority:**
- Fix credential sharing vulnerability (unique passwords per host)
- Implement Discord notifications for automation steps
- SSH hardening (disable root, key-only auth)

---

## 📸 VM Snapshots

**Created:**
- "Sprint 1 - Services Baseline" (both VMs)
  - Ubuntu: LAMP stack installed, running
  - Fedora: Mail/web stack installed, running
  - Baseline discovery reports generated

**Rollback procedure:**
```
VMware → VM → Snapshot → Revert to "Sprint 1 - Services Baseline"
```

---

## ✅ Sprint 1 Completion Criteria

- [x] 2 VMs operational with SSH access
- [x] Services installed and running on both VMs
- [x] All 3 playbooks (00, 01, 02) execute successfully
- [x] Baseline discovery reports generated
- [x] Inventory contains priority groups
- [x] Documentation complete
- [x] Committed to `v2-rebuild` branch
- [x] VM snapshots created

**Sprint 1 Status: COMPLETE ✅**

**Date Completed:** {{ ansible_date_time.date }}  
**Time Invested:** ~2 hours (VM setup + service install + testing)

---

## 📝 Git Commit Message Template

```
Sprint 1: Complete - Inventory & Discovery

Deliverables:
- Created 2 VMs (Ubuntu 24.04 Ecom, Fedora 43 Webmail)
- Validated SSH connectivity (Kali WSL control node)
- Installed baseline services (web, mail, database)
- Created discovery playbook (02-discover-hosts.yml)
- Enhanced inventory with priority groups
- Generated baseline reports for both hosts

Testing:
- Hello-world: 2/2 reachable ✅
- Environment validation: 2/2 ready ✅
- Discovery: Reports generated ✅
- Services confirmed running ✅

Next: Sprint 2 - Secrets & Password Management
```
