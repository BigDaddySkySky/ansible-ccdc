# Role: paloalto_firewall

Purpose
- Push NAT and security rules to the Palo Alto for the Linux segment without altering interfaces or IP assignments.

When to Run
- After host hardening if the Palo Alto is reachable; invoked by `playbooks/32-configure-palo.yml`.

Variables Required
- Network map from `group_vars/all/competition.yml`: `ecom_private_ip/public_ip`, `webmail_private_ip/public_ip`, `splunk_private_ip/public_ip`, `linux_lan_cidr`, `ubuntu_wks_subnet`, `palo_mgmt_ip`.
- Role vars: `palo_zone_outside`, `palo_zone_inside`, `palo_zone_ftd`, `palo_log_forwarding_profile`.
- Vault creds: `vault_palo_admin_user`, `vault_palo_admin_password`.

Dependencies
- Collection: `paloaltonetworks.panos`.
- Connection settings: `group_vars/palo_firewalls/connection.yml` (httpapi over https, validate_certs false).

Run Steps
1) Confirm Palo is reachable on mgmt IP over HTTPS.
2) `ansible-playbook playbooks/32-configure-palo.yml` (hosts: palo_firewalls).

Validation (Scoring-Aligned)
- Zones exist: outside/inside/ftd-zone.
- NAT rules: `nat-ecom`, `nat-webmail`, `nat-splunk`, `nat-lan-outbound` present.
- Security rules allow HTTP/HTTPS to ecom/splunk, SMTP/POP3 to webmail, ICMP any-any, and mgmt from Ubuntu WKS subnet.
- From scoring side: confirm 80/443/25/110 and ICMP reach appropriate servers.

White Team Visibility
- No interface renumbering or hostname changes; only NAT/policy for required services and mgmt; logging uses provided profile.

Inject Impact
- Automates edge configuration so responders can prioritize inject tasks and host work.
