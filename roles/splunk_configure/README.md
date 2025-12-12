# Role: splunk_configure

Purpose
- Initialize Splunk Enterprise: stop/clean state, set admin password, accept license, and open the UI port without touching IP/hostnames.

When to Run
- Once after Splunk VM deployment; before `splunk_harden` and before forwarders; typically after password rotation.

Variables Required
- Host vault: `vault_splunk_admin_password`.
- Inventory connection vars (`ansible_user`, `ansible_become_password`).

Dependencies
- firewalld (opens 8000/tcp).
- Splunk installed at /opt/splunk running as user `splunk`.

Run Steps
1) Ensure host reachable with sudo.
2) `ansible-playbook playbooks/40-harden-splunk.yml` is for hardening; for configure run role directly or via a dedicated play (not yet numbered) if needed.

Validation (Scoring-Aligned)
- Service: `/opt/splunk/bin/splunk status` -> running.
- UI: http://<splunk_ip>:8000 returns 200/302.
- REST: task checks https://127.0.0.1:8089/services/server/info with admin password.
- Scored services: no change to 22/80/443/25/110/21/53/DNS/ICMP on other hosts.

White Team Visibility
- Cleans Splunk local state and sets admin password; opens only UI port; no IP/hostname changes.

Inject Impact
- Automates initial setup so teammates avoid console time and can handle injects faster.
