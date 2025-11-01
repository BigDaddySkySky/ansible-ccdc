# VyOS Quick Reference Card - CCDC 2025

## 🚨 EMERGENCY FIRST STEPS
```bash
# 1. Change password NOW
configure
set system login user vyos authentication plaintext-password 'NewP@ss123!'
commit
save

# 2. Basic protection
set firewall name WAN-LOCAL default-action drop
set firewall name WAN-LOCAL rule 1 action accept
set firewall name WAN-LOCAL rule 1 state established enable
set firewall name WAN-LOCAL rule 1 state related enable
commit
save
```

## 📋 Essential Commands

| Action | Command |
|--------|---------|
| Enter config mode | `configure` |
| Apply changes | `commit` |
| Save permanently | `save` |
| Exit config | `exit` |
| View config | `show configuration` |
| Get help | `?` or `<TAB>` |

## 🔧 Common Tasks

### View Status
```bash
show interfaces
show ip route
show nat source translations
show log tail 20
```

### Basic NAT Setup
```bash
configure
set nat source rule 100 outbound-interface 'eth0'
set nat source rule 100 source address '172.16.101.0/24'
set nat source rule 100 translation address 'masquerade'
commit
save
```

### Static Route
```bash
configure
set protocols static route 0.0.0.0/0 next-hop 172.31.X.1
commit
save
```

### Port Forward
```bash
configure
set nat destination rule 10 destination port 80
set nat destination rule 10 inbound-interface 'eth0'
set nat destination rule 10 protocol tcp
set nat destination rule 10 translation address 172.20.242.101
commit
save
```

## 🛡️ Security Essentials

```bash
# Restrict SSH
set service ssh listen-address 172.16.101.1

# Basic firewall
set firewall name WAN-LOCAL default-action drop
set firewall name WAN-LOCAL rule 1 action accept
set firewall name WAN-LOCAL rule 1 state established enable
set firewall name WAN-LOCAL rule 1 state related enable

# Logging
set system syslog global facility all level info
```

## 🔍 Troubleshooting

```bash
ping 8.8.8.8                    # Test connectivity
show log tail 50                # Recent logs
show conntrack table ipv4       # Active connections
monitor traffic interface eth0   # Packet capture
reset interfaces ethernet eth0   # Reset interface
```

## 💾 Backup/Restore

```bash
# Backup
show configuration commands > /config/backup.conf

# Rollback
rollback 1
commit
save
```

## ⚠️ REMEMBER

✅ Always `commit` AND `save`  
✅ Test after every change  
✅ Keep ICMP enabled  
✅ Don't change IPs without inject  
✅ Document everything  

❌ Don't forget to save  
❌ Don't block scoring engine  
❌ Don't scan other teams  
❌ Don't disable all services  

## 📊 Your Network (TeamX)

```
WAN: eth0 = 172.31.X.2/29 → Gateway: 172.31.X.1
LAN1: eth1 = 172.16.101.1/24 (PaloAlto side)
LAN2: eth2 = 172.16.102.1/24 (Cisco FTD side)
Public IPs: 172.25.X.0/24
```

## 🎯 Competition Priorities

**0-5 min**: Change password, basic security  
**5-15 min**: NAT, routing, connectivity  
**15-30 min**: Firewall rules, hardening  
**30+ min**: Monitoring, injects, incident response
