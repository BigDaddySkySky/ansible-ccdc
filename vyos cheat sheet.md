# VyOS Router Cheat Sheet - MWCCDC 2025

## Initial Access
- **Default credentials**: `vyos:changeme`
- **Access via**: SSH or direct console from NETLAB+™ VE

## Command Modes

### Operational Mode (default)
```bash
vyos@vyos:~$
```
Read-only mode for viewing status and running diagnostics.

### Configuration Mode
```bash
configure
```
Enters configuration mode (prompt changes to `#`).

### Exit Configuration Mode
```bash
exit          # Exit config mode
exit discard  # Exit without saving changes
```

---

## CRITICAL: Save Your Changes!

### Save and Apply Configuration
```bash
commit          # Apply changes (temporary)
save            # Save to startup config
commit-archive  # Save with archive/backup
```

### View Changes Before Committing
```bash
compare         # Show uncommitted changes
```

---

## Basic Navigation & Help

```bash
show <TAB>              # Auto-complete in operational mode
set <TAB>               # Auto-complete in config mode
?                       # Context-sensitive help
show configuration      # View running config
show configuration commands  # View config as commands
```

---

## Interface Configuration

### View Interfaces
```bash
# Operational mode
show interfaces
show interfaces detail
show interfaces ethernet eth0
```

### Configure Interface (in config mode)
```bash
configure
set interfaces ethernet eth0 address '172.31.X.2/29'
set interfaces ethernet eth0 description 'WAN'
set interfaces ethernet eth1 address '172.16.101.1/24'
set interfaces ethernet eth1 description 'LAN1-PaloAlto'
set interfaces ethernet eth2 address '172.16.102.1/24'
set interfaces ethernet eth2 description 'LAN2-CiscoFTD'
commit
save
```

### Disable/Enable Interface
```bash
set interfaces ethernet eth0 disable
delete interfaces ethernet eth0 disable
```

---

## IP and Routing

### View Routing Table
```bash
show ip route
show ip route summary
```

### Static Routes
```bash
configure
set protocols static route 0.0.0.0/0 next-hop 172.31.X.1
set protocols static route 172.20.240.0/24 next-hop 172.16.102.254
set protocols static route 172.20.242.0/24 next-hop 172.16.101.254
commit
save
```

### Default Gateway
```bash
set protocols static route 0.0.0.0/0 next-hop 172.31.X.1
```

---

## NAT Configuration

### Source NAT (PAT/Overload)
```bash
configure
# NAT outbound traffic from LAN1
set nat source rule 10 outbound-interface 'eth0'
set nat source rule 10 source address '172.16.101.0/24'
set nat source rule 10 translation address 'masquerade'

# NAT outbound traffic from LAN2
set nat source rule 20 outbound-interface 'eth0'
set nat source rule 20 source address '172.16.102.0/24'
set nat source rule 20 translation address 'masquerade'
commit
save
```

### Destination NAT (Port Forwarding)
```bash
# Example: Forward external port 80 to internal web server
set nat destination rule 10 destination port 80
set nat destination rule 10 inbound-interface 'eth0'
set nat destination rule 10 protocol tcp
set nat destination rule 10 translation address 172.20.242.101
set nat destination rule 10 translation port 80
```

### View NAT
```bash
show nat source rules
show nat destination rules
show nat source statistics
show nat source translations
```

---

## Firewall Configuration

### Zone-Based Firewall Structure
```bash
configure

# Define zones
set zone-policy zone WAN interface eth0
set zone-policy zone LAN1 interface eth1
set zone-policy zone LAN2 interface eth2

# Define default actions
set zone-policy zone WAN default-action drop
set zone-policy zone LAN1 default-action drop
set zone-policy zone LAN2 default-action drop

# Allow established/related
set zone-policy zone WAN from LAN1 firewall name LAN1-TO-WAN
set zone-policy zone WAN from LAN2 firewall name LAN2-TO-WAN

# Create firewall rules
set firewall name LAN1-TO-WAN default-action drop
set firewall name LAN1-TO-WAN rule 1 action accept
set firewall name LAN1-TO-WAN rule 1 state established enable
set firewall name LAN1-TO-WAN rule 1 state related enable

commit
save
```

### Basic Firewall Rules
```bash
# Allow established/related
set firewall name WAN-LOCAL default-action drop
set firewall name WAN-LOCAL rule 1 action accept
set firewall name WAN-LOCAL rule 1 state established enable
set firewall name WAN-LOCAL rule 1 state related enable

# Allow SSH from specific source
set firewall name WAN-LOCAL rule 10 action accept
set firewall name WAN-LOCAL rule 10 protocol tcp
set firewall name WAN-LOCAL rule 10 destination port 22
set firewall name WAN-LOCAL rule 10 source address 172.31.X.0/24

# Drop everything else (implicit with default-action drop)
```

### View Firewall
```bash
show firewall
show firewall name WAN-LOCAL
show firewall statistics
show zone-policy
```

---

## DNS Configuration

### Set DNS Servers
```bash
configure
set system name-server 8.8.8.8
set system name-server 8.8.4.4
commit
save
```

### DNS Forwarding (Local DNS Cache)
```bash
set service dns forwarding listen-address 172.16.101.1
set service dns forwarding listen-address 172.16.102.1
set service dns forwarding name-server 8.8.8.8
set service dns forwarding name-server 8.8.4.4
```

---

## System Configuration

### Change Hostname
```bash
configure
set system host-name vyos-teamX
commit
save
```

### Set Time Zone
```bash
set system time-zone America/Chicago
```

### NTP Configuration
```bash
set system ntp server 0.pool.ntp.org
set system ntp server 1.pool.ntp.org
```

### View System Info
```bash
show version
show system image
show system uptime
show system memory
show system storage
```

---

## User Management & Security

### Change Password (CRITICAL - Do This First!)
```bash
configure
set system login user vyos authentication plaintext-password 'NewStrongPassword123!'
commit
save
```

### Add New User
```bash
set system login user ccdc authentication plaintext-password 'SecurePass123!'
set system login user ccdc level admin
```

### SSH Configuration
```bash
# Disable root login
set service ssh disable-password-authentication
set service ssh port 22

# Restrict SSH access
set service ssh listen-address 172.16.101.1
set service ssh listen-address 172.16.102.1

# Enable SSH (if needed)
set service ssh
```

### Delete User
```bash
delete system login user olduser
```

---

## Logging & Monitoring

### View Logs
```bash
show log
show log tail
show log tail 50
show log | match ssh
show log | match firewall
```

### Configure Logging
```bash
configure
set system syslog global facility all level info
set system syslog host 172.20.242.20 facility all level info
commit
save
```

### Monitor Traffic
```bash
monitor interfaces ethernet eth0
monitor firewall name WAN-LOCAL
```

---

## Troubleshooting Commands

### Connectivity Testing
```bash
ping 8.8.8.8
ping 172.20.242.101
traceroute 8.8.8.8
```

### Interface Status
```bash
show interfaces
show interfaces ethernet eth0
show interfaces counters
```

### Show ARP Table
```bash
show arp
```

### Show Connections
```bash
show conntrack table ipv4
```

### Packet Capture
```bash
monitor traffic interface eth0
monitor traffic interface eth0 filter "port 22"
```

### Reset Interface
```bash
reset interfaces ethernet eth0
```

---

## Configuration Management

### Backup Configuration
```bash
show configuration commands > /config/backup-$(date +%Y%m%d-%H%M%S).conf
```

### Compare Configurations
```bash
compare           # Compare working vs active
compare saved     # Compare working vs saved
```

### Rollback Configuration
```bash
rollback 0        # Rollback to last commit
rollback 1        # Rollback to commit before last
show system commit
```

### Load Configuration from File
```bash
load /config/backup-20251018.conf
commit
save
```

---

## Quick Security Hardening Checklist

### Priority 1: Immediate Actions (First 5 Minutes)
```bash
configure

# 1. Change default password
set system login user vyos authentication plaintext-password 'Str0ngP@ssw0rd123!'

# 2. Restrict SSH access
set service ssh listen-address 172.16.101.1
set service ssh listen-address 172.16.102.1

# 3. Basic firewall - drop by default
set firewall name WAN-LOCAL default-action drop
set firewall name WAN-LOCAL rule 1 action accept
set firewall name WAN-LOCAL rule 1 state established enable
set firewall name WAN-LOCAL rule 1 state related enable

commit
save
```

### Priority 2: Core Network Setup (Minutes 5-15)
```bash
# 4. Verify interface configs
show interfaces

# 5. Configure NAT for internet access
set nat source rule 100 outbound-interface 'eth0'
set nat source rule 100 source address '172.16.101.0/24'
set nat source rule 100 translation address 'masquerade'

set nat source rule 110 outbound-interface 'eth0'
set nat source rule 110 source address '172.16.102.0/24'
set nat source rule 110 translation address 'masquerade'

# 6. Set up default route
set protocols static route 0.0.0.0/0 next-hop 172.31.X.1

commit
save
```

### Priority 3: Enhanced Security (Minutes 15-30)
```bash
# 7. Disable unnecessary services
delete service dhcp-server
delete service dhcpv6-server

# 8. Enable logging
set system syslog global facility all level info

# 9. Configure NTP
set system ntp server 0.pool.ntp.org

# 10. Harden SSH
set service ssh protocol-version v2

commit
save
```

---

## CCDC Competition-Specific Notes

### Your Network Layout (Per Team)
```
External (WAN): eth0 - 172.31.X.2/29
Gateway: 172.31.X.1
Public IPs: 172.25.X.0/24

LAN1 (PaloAlto): eth1 - 172.16.101.1/24
LAN2 (CiscoFTD): eth2 - 172.16.102.1/24
```

### Critical Services to Maintain
- Routing between zones
- NAT for outbound internet
- ICMP (ping) must be maintained
- Port forwarding for scored services

### Competition Rules Reminders
- Do NOT change IP addresses unless instructed by inject
- Do NOT change hostnames unless instructed
- Do NOT block ICMP completely
- Do NOT perform offensive actions against other teams
- Monitor inject tasks regularly via NISE portal

---

## Emergency Commands

### Factory Reset (Last Resort!)
```bash
install image     # Reinstall system
load /opt/vyatta/etc/config.boot.default
commit
save
reboot
```

### Quick Service Recovery
```bash
# If you break something
configure
rollback 1
commit
save
```

---

## Useful One-Liners

```bash
# Quick status check
show interfaces brief; show ip route summary; show nat source statistics

# Find your public IP
show interfaces ethernet eth0 | grep "inet "

# Check if NAT is working
show nat source translations

# Monitor live connections
watch -n 1 show conntrack table ipv4

# Check for Red Team activity
show log tail 100 | match firewall
```

---

## Documentation Commands for Injects

```bash
# Screenshot alternative - output to file
show configuration commands > /tmp/config-snapshot.txt
show interfaces > /tmp/interfaces-snapshot.txt
show ip route > /tmp/routing-snapshot.txt
show nat source rules > /tmp/nat-snapshot.txt

# Access files from NETLAB console or via SCP
```

---

## Red Team Defense Tips

1. **Monitor logs constantly**: `show log tail 50`
2. **Watch connections**: `show conntrack table ipv4`
3. **Track firewall hits**: `show firewall statistics`
4. **Rate limit SSH**: Consider fail2ban-like rules in firewall
5. **Document everything**: Keep notes of all changes

---

## Common Mistakes to Avoid

1. ❌ Forgetting to `commit` after configuration changes
2. ❌ Forgetting to `save` after commit (changes lost on reboot)
3. ❌ Blocking ICMP completely (breaks scoring)
4. ❌ Changing interface IPs without inject permission
5. ❌ Making firewall rules too restrictive (breaks services)
6. ❌ Not testing after changes

---

## Quick Reference: Command Hierarchy

```
Configuration Mode (configure):
├── interfaces
│   └── ethernet ethX
│       ├── address
│       ├── description
│       └── disable
├── protocols
│   └── static
│       └── route
├── nat
│   ├── source
│   └── destination
├── firewall
│   └── name RULESET
│       ├── default-action
│       └── rule X
├── zone-policy
│   └── zone ZONENAME
├── service
│   ├── ssh
│   └── dns
└── system
    ├── host-name
    ├── login
    ├── name-server
    └── time-zone
```

---

## Resource Links

- VyOS Documentation: https://docs.vyos.io/
- VyOS Wiki: https://wiki.vyos.net/
- Quick Start: https://docs.vyos.io/en/latest/quick-start.html

---

## Competition Day Workflow

### 🏁 Start (Minute 0-5)
1. Log in with default credentials
2. Change password immediately
3. `show interfaces` - verify connectivity
4. `show configuration` - understand current setup

### 🔧 Setup (Minute 5-20)
1. Configure NAT
2. Set up static routes
3. Basic firewall rules
4. Test connectivity from internal hosts

### 🔒 Hardening (Minute 20-40)
1. Restrict SSH access
2. Zone-based firewall
3. Logging configuration
4. Service lockdown

### 🛡️ Defense (Ongoing)
1. Monitor logs continuously
2. Watch for Red Team activity
3. Respond to injects
4. Document incidents

**Good luck in the competition! Remember: COMMIT and SAVE!** 🚀
