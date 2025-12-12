# Role: splunk_harden

Purpose
- Safe-mode hardening for Splunk Enterprise: open mgmt/receiver ports, enable key log inputs, deploy team dashboards/saved searches, and enable boot-start without changing IPs/hostnames.

When to Run
- After `splunk_configure` completes and before universal forwarders send data; invoked by `playbooks/40-harden-splunk.yml`.

Variables Required
- Uses host vault for `ansible_become_password`.
- Templates only (no extra vars): inputs, dashboards, saved searches.

Dependencies
- firewalld present; Splunk installed at /opt/splunk running as `splunk`.
- Handler `restart splunk` in `handlers/main.yml`.

Run Steps
1) Ensure Splunk is configured and running.
2) `ansible-playbook playbooks/40-harden-splunk.yml` (hosts: splunk_vm).

Validation (Scoring-Aligned)
- Ports: `ss -tlnp | grep -E "8089|9997"` -> listening.
- Files: `/opt/splunk/etc/system/local/inputs.conf` includes secure/messages/audit; dashboards in `search/local/data/ui/views`.
- Service: `systemctl status splunk` or `/opt/splunk/bin/splunk status` -> running after handler.
- Scored services unaffected: confirm 22/80/443/25/110/21/53 and ICMP on other hosts still OK.

White Team Visibility
- Opens only Splunk mgmt/logging ports; adds log inputs/dashboards; no network/IP changes.

Inject Impact
- Provides ready searches/dashboards so responders can quickly build reports and handle injects.
