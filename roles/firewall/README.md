# firewall

Purpose:
- Apply host-based firewall rules for competition systems
- Restrict inbound traffic to required services only

Used by:
- `critical-path` playbook

Changes:
- Configures UFW (Debian/Ubuntu) or firewalld (Fedora/RHEL)
- Sets default deny inbound policy
- Allows SSH and scored services
- Applies basic kernel network hardening

Key Inputs (vars):
- firewall_enabled
- firewall_scored_services
- firewall_additional_services
- firewall_enable_rate_limiting

Notes:
- SSH must be allowed before applying
- Do not block ICMP unless explicitly directed
- Test on a single host before broad deployment
