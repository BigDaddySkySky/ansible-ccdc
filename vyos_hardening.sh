#!/bin/bash
# VyOS CCDC Hardening Script
# Configures firewall, NAT, and security while maintaining service availability

set -e

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

# Start configuration
echo "Configuring VyOS router..."

# Enter configuration mode
vtysh << 'EOF'
configure terminal

! ==========================================
! Basic System Hardening
! ==========================================

! Set hostname
set system host-name ccdc-vyos

! Enable SSH hardening
set service ssh disable-password-authentication
set service ssh port 22
set service ssh protocol-version 2

! Disable unnecessary services
delete service telnet
delete service ftp

! Set timezone
set system time-zone America/Chicago

! Enable NTP (if needed for logging)
set system ntp server time.google.com
set system ntp server time.cloudflare.com

! ==========================================
! Logging Configuration
! ==========================================

set system syslog global facility all level info
set system syslog global facility protocols level debug
set system syslog host ${CORE_IP} facility all level info

! ==========================================
! Interface Configuration
! ==========================================

! External interface
set interfaces ethernet eth0 address ${EXTERNAL_NET}
set interfaces ethernet eth0 description "WAN-to-Core"

! Internal interfaces
set interfaces ethernet eth1 address ${NET1}
set interfaces ethernet eth1 description "LAN-PaloAlto"

set interfaces ethernet eth2 address ${NET2}
set interfaces ethernet eth2 description "LAN-CiscoFTD"

! ==========================================
! Static Routes
! ==========================================

set protocols static route 0.0.0.0/0 next-hop ${CORE_IP}

! ==========================================
! NAT Configuration (Source NAT)
! ==========================================

! NAT for Palo Alto segment
set nat source rule 10 outbound-interface eth0
set nat source rule 10 source address 172.16.101.0/24
set nat source rule 10 translation address ${PUBLIC_NET}

! NAT for Cisco FTD segment
set nat source rule 20 outbound-interface eth0
set nat source rule 20 source address 172.16.102.0/24
set nat source rule 20 translation address ${PUBLIC_NET}

! ==========================================
! Firewall Zones
! ==========================================

set zone-policy zone WAN description "External WAN zone"
set zone-policy zone WAN interface eth0

set zone-policy zone LAN1 description "Internal LAN - Palo Alto"
set zone-policy zone LAN1 interface eth1

set zone-policy zone LAN2 description "Internal LAN - Cisco FTD"
set zone-policy zone LAN2 interface eth2

set zone-policy zone LOCAL description "Router itself"
set zone-policy zone LOCAL local-zone

! ==========================================
! Firewall Rules - LOCAL to WAN
! ==========================================

set firewall name LOCAL-WAN default-action drop
set firewall name LOCAL-WAN description "Traffic from router to WAN"
set firewall name LOCAL-WAN enable-default-log

! Allow established/related
set firewall name LOCAL-WAN rule 10 action accept
set firewall name LOCAL-WAN rule 10 state established enable
set firewall name LOCAL-WAN rule 10 state related enable
set firewall name LOCAL-WAN rule 10 description "Allow established/related"

! Allow DNS queries
set firewall name LOCAL-WAN rule 20 action accept
set firewall name LOCAL-WAN rule 20 protocol udp
set firewall name LOCAL-WAN rule 20 destination port 53
set firewall name LOCAL-WAN rule 20 description "Allow DNS queries"

! Allow NTP
set firewall name LOCAL-WAN rule 30 action accept
set firewall name LOCAL-WAN rule 30 protocol udp
set firewall name LOCAL-WAN rule 30 destination port 123
set firewall name LOCAL-WAN rule 30 description "Allow NTP"

! Allow HTTP/HTTPS for updates
set firewall name LOCAL-WAN rule 40 action accept
set firewall name LOCAL-WAN rule 40 protocol tcp
set firewall name LOCAL-WAN rule 40 destination port 80,443
set firewall name LOCAL-WAN rule 40 description "Allow HTTP/HTTPS"

! ==========================================
! Firewall Rules - WAN to LOCAL
! ==========================================

set firewall name WAN-LOCAL default-action drop
set firewall name WAN-LOCAL description "Traffic from WAN to router"
set firewall name WAN-LOCAL enable-default-log

! Allow established/related
set firewall name WAN-LOCAL rule 10 action accept
set firewall name WAN-LOCAL rule 10 state established enable
set firewall name WAN-LOCAL rule 10 state related enable
set firewall name WAN-LOCAL rule 10 description "Allow established/related"

! Allow ICMP (for scoring)
set firewall name WAN-LOCAL rule 20 action accept
set firewall name WAN-LOCAL rule 20 protocol icmp
set firewall name WAN-LOCAL rule 20 description "Allow ICMP ping"

! Rate limit SSH from WAN
set firewall name WAN-LOCAL rule 30 action accept
set firewall name WAN-LOCAL rule 30 protocol tcp
set firewall name WAN-LOCAL rule 30 destination port 22
set firewall name WAN-LOCAL rule 30 state new enable
set firewall name WAN-LOCAL rule 30 recent count 3
set firewall name WAN-LOCAL rule 30 recent time 60
set firewall name WAN-LOCAL rule 30 description "Rate-limited SSH"

! ==========================================
! Firewall Rules - LAN to WAN (Allow Internet)
! ==========================================

set firewall name LAN-WAN default-action accept
set firewall name LAN-WAN description "LAN to Internet"

! Log suspicious traffic
set firewall name LAN-WAN rule 10 action accept
set firewall name LAN-WAN rule 10 log enable
set firewall name LAN-WAN rule 10 protocol tcp
set firewall name LAN-WAN rule 10 destination port 22,23,3389
set firewall name LAN-WAN rule 10 description "Log outbound management protocols"

! Block private IP ranges on outbound (anti-spoofing)
set firewall name LAN-WAN rule 100 action drop
set firewall name LAN-WAN rule 100 destination address 10.0.0.0/8
set firewall name LAN-WAN rule 100 log enable
set firewall name LAN-WAN rule 100 description "Block RFC1918 10.0.0.0/8"

set firewall name LAN-WAN rule 110 action drop
set firewall name LAN-WAN rule 110 destination address 172.16.0.0/12
set firewall name LAN-WAN rule 110 log enable
set firewall name LAN-WAN rule 110 description "Block RFC1918 172.16.0.0/12"

set firewall name LAN-WAN rule 120 action drop
set firewall name LAN-WAN rule 120 destination address 192.168.0.0/16
set firewall name LAN-WAN rule 120 log enable
set firewall name LAN-WAN rule 120 description "Block RFC1918 192.168.0.0/16"

! ==========================================
! Firewall Rules - WAN to LAN (Strict)
! ==========================================

set firewall name WAN-LAN default-action drop
set firewall name WAN-LAN description "WAN to Internal LANs"
set firewall name WAN-LAN enable-default-log

! Allow established/related
set firewall name WAN-LAN rule 10 action accept
set firewall name WAN-LAN rule 10 state established enable
set firewall name WAN-LAN rule 10 state related enable
set firewall name WAN-LAN rule 10 description "Allow established/related"

! Allow ICMP for scoring
set firewall name WAN-LAN rule 20 action accept
set firewall name WAN-LAN rule 20 protocol icmp
set firewall name WAN-LAN rule 20 description "Allow ICMP"

! Allow HTTP/HTTPS to web servers (modify IPs as needed)
set firewall name WAN-LAN rule 100 action accept
set firewall name WAN-LAN rule 100 protocol tcp
set firewall name WAN-LAN rule 100 destination port 80,443
set firewall name WAN-LAN rule 100 description "Allow HTTP/HTTPS to services"

! Allow SMTP (port 25)
set firewall name WAN-LAN rule 110 action accept
set firewall name WAN-LAN rule 110 protocol tcp
set firewall name WAN-LAN rule 110 destination port 25
set firewall name WAN-LAN rule 110 description "Allow SMTP"

! Allow POP3 (port 110)
set firewall name WAN-LAN rule 120 action accept
set firewall name WAN-LAN rule 120 protocol tcp
set firewall name WAN-LAN rule 120 destination port 110
set firewall name WAN-LAN rule 120 description "Allow POP3"

! Allow FTP (ports 20-21)
set firewall name WAN-LAN rule 130 action accept
set firewall name WAN-LAN rule 130 protocol tcp
set firewall name WAN-LAN rule 130 destination port 20-21
set firewall name WAN-LAN rule 130 description "Allow FTP"

! Allow DNS (port 53)
set firewall name WAN-LAN rule 140 action accept
set firewall name WAN-LAN rule 140 protocol udp
set firewall name WAN-LAN rule 140 destination port 53
set firewall name WAN-LAN rule 140 description "Allow DNS UDP"

set firewall name WAN-LAN rule 141 action accept
set firewall name WAN-LAN rule 141 protocol tcp
set firewall name WAN-LAN rule 141 destination port 53
set firewall name WAN-LAN rule 141 description "Allow DNS TCP"

! ==========================================
! Firewall Rules - LAN to LOCAL
! ==========================================

set firewall name LAN-LOCAL default-action drop
set firewall name LAN-LOCAL description "LAN to router"

! Allow established/related
set firewall name LAN-LOCAL rule 10 action accept
set firewall name LAN-LOCAL rule 10 state established enable
set firewall name LAN-LOCAL rule 10 state related enable

! Allow ICMP
set firewall name LAN-LOCAL rule 20 action accept
set firewall name LAN-LOCAL rule 20 protocol icmp

! Allow SSH from internal
set firewall name LAN-LOCAL rule 30 action accept
set firewall name LAN-LOCAL rule 30 protocol tcp
set firewall name LAN-LOCAL rule 30 destination port 22

! Allow DNS queries to router
set firewall name LAN-LOCAL rule 40 action accept
set firewall name LAN-LOCAL rule 40 protocol udp
set firewall name LAN-LOCAL rule 40 destination port 53

! ==========================================
! Firewall Rules - LOCAL to LAN
! ==========================================

set firewall name LOCAL-LAN default-action accept
set firewall name LOCAL-LAN description "Router to LAN"

! ==========================================
! Inter-LAN Traffic (LAN1 to LAN2)
! ==========================================

set firewall name LAN-LAN default-action accept
set firewall name LAN-LAN description "Inter-LAN traffic"

! Allow established/related
set firewall name LAN-LAN rule 10 action accept
set firewall name LAN-LAN rule 10 state established enable
set firewall name LAN-LAN rule 10 state related enable

! ==========================================
! Apply Zone Policies
! ==========================================

set zone-policy zone WAN from LOCAL firewall name LOCAL-WAN
set zone-policy zone LOCAL from WAN firewall name WAN-LOCAL
set zone-policy zone WAN from LAN1 firewall name LAN-WAN
set zone-policy zone WAN from LAN2 firewall name LAN-WAN
set zone-policy zone LAN1 from WAN firewall name WAN-LAN
set zone-policy zone LAN2 from WAN firewall name WAN-LAN
set zone-policy zone LOCAL from LAN1 firewall name LAN-LOCAL
set zone-policy zone LOCAL from LAN2 firewall name LAN-LOCAL
set zone-policy zone LAN1 from LOCAL firewall name LOCAL-LAN
set zone-policy zone LAN2 from LOCAL firewall name LOCAL-LAN
set zone-policy zone LAN1 from LAN2 firewall name LAN-LAN
set zone-policy zone LAN2 from LAN1 firewall name LAN-LAN

! ==========================================
! Connection Tracking
! ==========================================

set system conntrack modules ftp
set system conntrack modules h323
set system conntrack modules nfs
set system conntrack modules pptp
set system conntrack modules sip
set system conntrack modules sqlnet
set system conntrack modules tftp

! ==========================================
! Rate Limiting and DoS Protection
! ==========================================

! SYN flood protection
set firewall syn-cookies enable

! ICMP rate limiting
set firewall all-ping enable
set firewall broadcast-ping disable

! ==========================================
! Save and Commit
! ==========================================

commit
save
exit
EOF

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
echo "  3. Check firewall logs: show log firewall"
echo "  4. Monitor connections: show firewall"
echo ""
echo "IMPORTANT: Change default credentials immediately!"
echo "  - Change VyOS user password: set system login user vyos authentication plaintext-password"
echo ""

exit 0
