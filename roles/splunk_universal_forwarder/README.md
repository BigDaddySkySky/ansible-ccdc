# Role: splunk_universal_forwarder

Purpose
- Install and configure Splunk UF on all Linux servers (except splunk_vm) and forward to the Splunk indexer without touching IPs/hostnames.

When to Run
- After Splunk indexer is up and reachable; called by `playbooks/50-deploy-forwarders.yml`.

Variables Required
- Defaults (see `defaults/main.yml`): `splunk_forwarder_home`, `splunk_forwarder_deb_url`, `splunk_forwarder_rpm_url`, `splunk_indexer_host`, `splunk_indexer_port`, `splunk_forwarder_user_default`.
- Inventory/host vault: `vault_host_password` for sudo, `splunk_vm` host to resolve indexer.

Dependencies
- Collections: `ansible.posix`, `community.general`.
- Packages: UF installer reachable from provided URLs or pre-staged; service account (`splunkfwd` or `splunk`) auto-detected.

Run Steps
1) Ensure `splunk_vm` is reachable and Splunk is running (ports 8089/9997).
2) `ansible-playbook playbooks/50-deploy-forwarders.yml` (targets `linux_servers:!splunk_vm`).

Validation (Scoring-Aligned)
- Service: `systemctl status SplunkForwarder` -> active.
- Forwarding: check `outputs.conf` target (`splunk_indexer_host:9997`).
- Inputs: `inputs.conf` contains auth/messages/audit logs.
- Scored services: confirm 22/80/443/25/110/21/53 and ICMP still reachable (no firewall changes here).

White Team Visibility
- Adds log forwarding only; no IP/hostname changes; no firewall edits; outbound to Splunk on 9997.

Inject Impact
- Automated log shipping reduces manual evidence collection; teammates can focus on inject write-ups.
