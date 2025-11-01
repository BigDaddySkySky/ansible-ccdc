#!/bin/vbash
# VyOS CCDC Hardening Script - Modern VyOS 1.4+ Syntax
# Configures firewall, NAT, and security while maintaining service availability

source /opt/vyatta/etc/functions/script-template

echo "=========================================="
echo "VyOS CCDC Competition Hardening Script"
echo "=========================================="
echo ""

# Prompt for team number
read -p "Enter your team number (1-20): " TEAM_NUM

# Validate team number
if ! [[ "$TEAM_NUM" =~ ^[0-9]+$ ]] || [ "$TEAM_NUM" -lt 1 ] || [ "$TEAM_NUM" -gt 20 ]; then
    echo "Error: Team number must be between 1 and 20"
    exit 1
fi

# Calculate IP ranges based on team number
TEAM_OFFSET=$((20 + TEAM_NUM))
EXTERNAL_NET="172.31.${TEAM_OFFSET}.2/29"
EXTERNAL_IP="172.31.${TEAM_OFFSET}.2"
CORE_IP="172.31.${TEAM_OFFSET}.1"
PUBLIC_NET="172.25.${TEAM_OFFSET}.0/24"

# Internal networks
NET1="172.16.101.1/24"  # Palo Alto side
NET2="172.16.102.1/24"  # Cisco FTD side

echo "Team $TEAM_NUM Configuration:"
echo "  External IP: $EXTERNAL_IP"
echo "  Public Pool: $PUBLIC_NET"
echo "  Internal Net1: $NET1"
echo "  Internal Net2: $NET2"
echo ""
read -p "Press Enter to continue or Ctrl+C to abort..."

echo ""
echo "Configuring VyOS router..."
echo ""

# Enter configuration mode
configure

# ==========================================
# Basic System Hardening
# ==========================================
echo ">>> Applying basic system hardening..."

set system host-name ccdc-vyos
set service ssh port 22
set service ssh protocol-version v2
delete service telnet 2>/dev/null || true
delete service ftp 2>/dev/null || true
set system time-zone America/Chicago
set system ntp server time.google.com
set system ntp server time.cloudflare.com

echo "✓ System hardening complete"
sleep 2

# ==========================================
# Logging Configuration
# ==========================================
echo ">>> Configuring logging..."

set system syslog global facility all level info
set system syslog global facility protocols level debug
set system syslog host ${CORE_IP} facility all level info

echo "✓ Logging configured"
sleep 2

# ==========================================
# Interface Configuration
# ==========================================
echo ">>> Configuring network interfaces..."

set interfaces ethernet eth0 address ${EXTERNAL_NET}
set interfaces ethernet eth0 description "WAN-to-Core"

set interfaces ethernet eth1 address ${NET1}
set interfaces ethernet eth1 description "LAN-PaloAlto"

set interfaces ethernet eth2 address ${NET2}
set interfaces ethernet eth2 description "LAN-CiscoFTD"

echo "✓ Interfaces configured"
sleep 2

# ==========================================
# Static Routes
# ==========================================
echo ">>> Configuring static routes..."

set protocols static route 0.0.0.0/0 next-hop ${CORE_IP}

echo "✓ Static routes configured"
sleep 2

# ==========================================
# NAT Configuration (Source NAT)
# ==========================================
echo ">>> Configuring NAT (Source NAT for internal networks)..."

set nat source rule 10 outbound-interface name eth0
set nat source rule 10 source address 172.16.101.0/24
set nat source rule 10 translation address ${PUBLIC_NET}

set nat source rule 20 outbound-interface name eth0
set nat source rule 20 source address 172.16.102.0/24
set nat source rule 20 translation address ${PUBLIC_NET}

echo "✓ NAT configured"
sleep 2

# ==========================================
# Firewall Zones
# ==========================================
echo ">>> Configuring firewall zones..."

set firewall zone WAN description "External WAN zone"
set firewall zone WAN interface eth0

set firewall zone LAN1 description "Internal LAN - Palo Alto"
set firewall zone LAN1 interface eth1

set firewall zone LAN2 description "Internal LAN - Cisco FTD"
set firewall zone LAN2 interface eth2

set firewall zone LOCAL description "Router itself"
set firewall zone LOCAL local-zone

echo "✓ Firewall zones configured"
sleep 2

# ==========================================
# Firewall Rules - LOCAL to WAN
# ==========================================
echo ">>> Configuring firewall rules for router (LOCAL zone)..."

set firewall ipv4 name LOCAL-WAN default-action drop
set firewall ipv4 name LOCAL-WAN description "Traffic from router to WAN"
set firewall ipv4 name LOCAL-WAN default-log

set firewall ipv4 name LOCAL-WAN rule 10 action accept
set firewall ipv4 name LOCAL-WAN rule 10 state established
set firewall ipv4 name LOCAL-WAN rule 10 state related
set firewall ipv4 name LOCAL-WAN rule 10 description "Allow established/related"

set firewall ipv4 name LOCAL-WAN rule 20 action accept
set firewall ipv4 name LOCAL-WAN rule 20 protocol udp
set firewall ipv4 name LOCAL-WAN rule 20 destination port 53
set firewall ipv4 name LOCAL-WAN rule 20 description "Allow DNS queries"

set firewall ipv4 name LOCAL-WAN rule 30 action accept
set firewall ipv4 name LOCAL-WAN rule 30 protocol udp
set firewall ipv4 name LOCAL-WAN rule 30 destination port 123
set firewall ipv4 name LOCAL-WAN rule 30 description "Allow NTP"

set firewall ipv4 name LOCAL-WAN rule 40 action accept
set firewall ipv4 name LOCAL-WAN rule 40 protocol tcp
set firewall ipv4 name LOCAL-WAN rule 40 destination port 80
set firewall ipv4 name LOCAL-WAN rule 40 description "Allow HTTP"

set firewall ipv4 name LOCAL-WAN rule 41 action accept
set firewall ipv4 name LOCAL-WAN rule 41 protocol tcp
set firewall ipv4 name LOCAL-WAN rule 41 destination port 443
set firewall ipv4 name LOCAL-WAN rule 41 description "Allow HTTPS"

# ==========================================
# Firewall Rules - WAN to LOCAL
# ==========================================

set firewall ipv4 name WAN-LOCAL default-action drop
set firewall ipv4 name WAN-LOCAL description "Traffic from WAN to router"
set firewall ipv4 name WAN-LOCAL default-log

set firewall ipv4 name WAN-LOCAL rule 10 action accept
set firewall ipv4 name WAN-LOCAL rule 10 state established
set firewall ipv4 name WAN-LOCAL rule 10 state related
set firewall ipv4 name WAN-LOCAL rule 10 description "Allow established/related"

set firewall ipv4 name WAN-LOCAL rule 20 action accept
set firewall ipv4 name WAN-LOCAL rule 20 protocol icmp
set firewall ipv4 name WAN-LOCAL rule 20 description "Allow ICMP ping"

set firewall ipv4 name WAN-LOCAL rule 30 action accept
set firewall ipv4 name WAN-LOCAL rule 30 protocol tcp
set firewall ipv4 name WAN-LOCAL rule 30 destination port 22
set firewall ipv4 name WAN-LOCAL rule 30 state new
set firewall ipv4 name WAN-LOCAL rule 30 recent count 3
set firewall ipv4 name WAN-LOCAL rule 30 recent time minute 1
set firewall ipv4 name WAN-LOCAL rule 30 description "Rate-limited SSH"

echo "✓ Router firewall rules configured"
sleep 2

# ==========================================
# Firewall Rules - LAN to WAN (Allow Internet)
# ==========================================
echo ">>> Configuring LAN to WAN firewall rules (outbound Internet access)..."

set firewall ipv4 name LAN-WAN default-action accept
set firewall ipv4 name LAN-WAN description "LAN to Internet"

set firewall ipv4 name LAN-WAN rule 10 action accept
set firewall ipv4 name LAN-WAN rule 10 log
set firewall ipv4 name LAN-WAN rule 10 protocol tcp
set firewall ipv4 name LAN-WAN rule 10 destination port 22
set firewall ipv4 name LAN-WAN rule 10 description "Log outbound SSH"

set firewall ipv4 name LAN-WAN rule 11 action accept
set firewall ipv4 name LAN-WAN rule 11 log
set firewall ipv4 name LAN-WAN rule 11 protocol tcp
set firewall ipv4 name LAN-WAN rule 11 destination port 23
set firewall ipv4 name LAN-WAN rule 11 description "Log outbound Telnet"

set firewall ipv4 name LAN-WAN rule 12 action accept
set firewall ipv4 name LAN-WAN rule 12 log
set firewall ipv4 name LAN-WAN rule 12 protocol tcp
set firewall ipv4 name LAN-WAN rule 12 destination port 3389
set firewall ipv4 name LAN-WAN rule 12 description "Log outbound RDP"

set firewall ipv4 name LAN-WAN rule 100 action drop
set firewall ipv4 name LAN-WAN rule 100 destination address 10.0.0.0/8
set firewall ipv4 name LAN-WAN rule 100 log
set firewall ipv4 name LAN-WAN rule 100 description "Block RFC1918 10.0.0.0/8"

set firewall ipv4 name LAN-WAN rule 110 action drop
set firewall ipv4 name LAN-WAN rule 110 destination address 172.16.0.0/12
set firewall ipv4 name LAN-WAN rule 110 log
set firewall ipv4 name LAN-WAN rule 110 description "Block RFC1918 172.16.0.0/12"

set firewall ipv4 name LAN-WAN rule 120 action drop
set firewall ipv4 name LAN-WAN rule 120 destination address 192.168.0.0/16
set firewall ipv4 name LAN-WAN rule 120 log
set firewall ipv4 name LAN-WAN rule 120 description "Block RFC1918 192.168.0.0/16"

echo "✓ LAN to WAN rules configured"
sleep 2

# ==========================================
# Firewall Rules - WAN to LAN (Strict)
# ==========================================
echo ">>> Configuring WAN to LAN firewall rules (CRITICAL for service scoring)..."

set firewall ipv4 name WAN-LAN default-action drop
set firewall ipv4 name WAN-LAN description "WAN to Internal LANs"
set firewall ipv4 name WAN-LAN default-log

set firewall ipv4 name WAN-LAN rule 10 action accept
set firewall ipv4 name WAN-LAN rule 10 state established
set firewall ipv4 name WAN-LAN rule 10 state related
set firewall ipv4 name WAN-LAN rule 10 description "Allow established/related"

set firewall ipv4 name WAN-LAN rule 20 action accept
set firewall ipv4 name WAN-LAN rule 20 protocol icmp
set firewall ipv4 name WAN-LAN rule 20 description "Allow ICMP"

set firewall ipv4 name WAN-LAN rule 100 action accept
set firewall ipv4 name WAN-LAN rule 100 protocol tcp
set firewall ipv4 name WAN-LAN rule 100 destination port 80
set firewall ipv4 name WAN-LAN rule 100 description "Allow HTTP"

set firewall ipv4 name WAN-LAN rule 101 action accept
set firewall ipv4 name WAN-LAN rule 101 protocol tcp
set firewall ipv4 name WAN-LAN rule 101 destination port 443
set firewall ipv4 name WAN-LAN rule 101 description "Allow HTTPS"

set firewall ipv4 name WAN-LAN rule 110 action accept
set firewall ipv4 name WAN-LAN rule 110 protocol tcp
set firewall ipv4 name WAN-LAN rule 110 destination port 25
set firewall ipv4 name WAN-LAN rule 110 description "Allow SMTP"

set firewall ipv4 name WAN-LAN rule 120 action accept
set firewall ipv4 name WAN-LAN rule 120 protocol tcp
set firewall ipv4 name WAN-LAN rule 120 destination port 110
set firewall ipv4 name WAN-LAN rule 120 description "Allow POP3"

set firewall ipv4 name WAN-LAN rule 130 action accept
set firewall ipv4 name WAN-LAN rule 130 protocol tcp
set firewall ipv4 name WAN-LAN rule 130 destination port 20
set firewall ipv4 name WAN-LAN rule 130 description "Allow FTP-DATA"

set firewall ipv4 name WAN-LAN rule 131 action accept
set firewall ipv4 name WAN-LAN rule 131 protocol tcp
set firewall ipv4 name WAN-LAN rule 131 destination port 21
set firewall ipv4 name WAN-LAN rule 131 description "Allow FTP"

set firewall ipv4 name WAN-LAN rule 140 action accept
set firewall ipv4 name WAN-LAN rule 140 protocol udp
set firewall ipv4 name WAN-LAN rule 140 destination port 53
set firewall ipv4 name WAN-LAN rule 140 description "Allow DNS UDP"

set firewall ipv4 name WAN-LAN rule 141 action accept
set firewall ipv4 name WAN-LAN rule 141 protocol tcp
set firewall ipv4 name WAN-LAN rule 141 destination port 53
set firewall ipv4 name WAN-LAN rule 141 description "Allow DNS TCP"

echo "✓ WAN to LAN rules configured (services should score)"
sleep 2

# ==========================================
# Firewall Rules - LAN to LOCAL
# ==========================================
echo ">>> Configuring LAN to router and inter-LAN firewall rules..."

set firewall ipv4 name LAN-LOCAL default-action drop
set firewall ipv4 name LAN-LOCAL description "LAN to router"

set firewall ipv4 name LAN-LOCAL rule 10 action accept
set firewall ipv4 name LAN-LOCAL rule 10 state established
set firewall ipv4 name LAN-LOCAL rule 10 state related

set firewall ipv4 name LAN-LOCAL rule 20 action accept
set firewall ipv4 name LAN-LOCAL rule 20 protocol icmp

set firewall ipv4 name LAN-LOCAL rule 30 action accept
set firewall ipv4 name LAN-LOCAL rule 30 protocol tcp
set firewall ipv4 name LAN-LOCAL rule 30 destination port 22

set firewall ipv4 name LAN-LOCAL rule 40 action accept
set firewall ipv4 name LAN-LOCAL rule 40 protocol udp
set firewall ipv4 name LAN-LOCAL rule 40 destination port 53

# ==========================================
# Firewall Rules - LOCAL to LAN
# ==========================================

set firewall ipv4 name LOCAL-LAN default-action accept
set firewall ipv4 name LOCAL-LAN description "Router to LAN"

# ==========================================
# Inter-LAN Traffic (LAN1 to LAN2)
# ==========================================

set firewall ipv4 name LAN-LAN default-action accept
set firewall ipv4 name LAN-LAN description "Inter-LAN traffic"

set firewall ipv4 name LAN-LAN rule 10 action accept
set firewall ipv4 name LAN-LAN rule 10 state established
set firewall ipv4 name LAN-LAN rule 10 state related

echo "✓ LAN and inter-LAN rules configured"
sleep 2

# ==========================================
# Apply Zone Policies
# ==========================================
echo ">>> Applying zone policies (linking zones to firewall rules)..."

set firewall zone WAN from LOCAL firewall name LOCAL-WAN
set firewall zone LOCAL from WAN firewall name WAN-LOCAL
set firewall zone WAN from LAN1 firewall name LAN-WAN
set firewall zone WAN from LAN2 firewall name LAN-WAN
set firewall zone LAN1 from WAN firewall name WAN-LAN
set firewall zone LAN2 from WAN firewall name WAN-LAN
set firewall zone LOCAL from LAN1 firewall name LAN-LOCAL
set firewall zone LOCAL from LAN2 firewall name LAN-LOCAL
set firewall zone LAN1 from LOCAL firewall name LOCAL-LAN
set firewall zone LAN2 from LOCAL firewall name LOCAL-LAN
set firewall zone LAN1 from LAN2 firewall name LAN-LAN
set firewall zone LAN2 from LAN1 firewall name LAN-LAN

echo "✓ Zone policies applied"
sleep 2

# ==========================================
# Connection Tracking
# ==========================================
echo ">>> Enabling connection tracking modules..."

set system conntrack modules ftp
set system conntrack modules h323
set system conntrack modules nfs
set system conntrack modules pptp
set system conntrack modules sip
set system conntrack modules sqlnet
set system conntrack modules tftp

echo "✓ Connection tracking modules enabled"
sleep 2

# ==========================================
# Rate Limiting and DoS Protection
# ==========================================
echo ">>> Enabling DoS protection features..."

set firewall global-options syn-cookies
set firewall global-options all-ping
set firewall global-options broadcast-ping disable

echo "✓ DoS protection enabled"
sleep 2

# ==========================================
# Commit and Save
# ==========================================
echo ">>> Committing configuration to active config..."
commit

if [ $? -ne 0 ]; then
    echo "ERROR: Configuration commit failed!"
    echo "Review errors above before proceeding."
    sleep 5
    exit
    exit 1
fi

echo "✓ Configuration committed"
sleep 2

echo ">>> Saving configuration to disk..."
save

if [ $? -ne 0 ]; then
    echo "ERROR: Configuration save failed!"
    echo "Changes are active but may not survive reboot."
    sleep 3
else
    echo "✓ Configuration saved to disk"
    sleep 1
fi

# Exit configuration mode
exit

echo ""
echo "=========================================="
echo "VyOS Configuration Complete!"
echo "=========================================="
echo ""
echo "Configuration Summary:"
echo "  - NAT configured for both internal networks"
echo "  - Zone-based firewall enabled"
echo "  - Required services allowed (HTTP, HTTPS, SMTP, POP3, FTP, DNS)"
echo "  - SSH rate limiting enabled"
echo "  - Connection tracking modules loaded"
echo "  - Logging enabled"
echo ""
echo "Next Steps:"
echo "  1. Verify connectivity: ping ${CORE_IP}"
echo "  2. Test NAT: ping 8.8.8.8 from internal hosts"
echo "  3. Check firewall: show firewall ipv4 name WAN-LAN"
echo "  4. Monitor zones: show firewall zone"
echo ""
echo "IMPORTANT: Change default credentials immediately!"
echo "  configure"
echo "  set system login user vyos authentication plaintext-password <new-password>"
echo "  commit"
echo "  save"
echo "  exit"
echo ""

exit 0
