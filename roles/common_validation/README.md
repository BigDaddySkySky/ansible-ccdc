# Role: common_validation

Purpose
- Post-hardening safety checks to confirm SSH and basic HTTP responsiveness remain intact.

When to Run
- End of hardening stack; included in `playbooks/30-hardening-main.yml`.

Variables Required
- Uses `ansible_host`; optional `ansible_run_tags` to decide HTTP probe.

Dependencies
- Modules `wait_for`, `uri`; assumes firewall role ran if HTTP tag present.

Run Steps
- Runs automatically with main stack; or `ansible-playbook playbooks/30-hardening-main.yml --tags common_validation` to isolate.

Validation
- Waits for SSH on port 22; asserts success.
- Optional HTTP GET to http://<host> (accepts 200/301/302/403/404).
- Debug summary per host.

White Team Visibility
- Read-only connectivity probes; no system changes; confirms scored services remain up.

Inject Impact
- Confirms automation didn't break scoring, freeing teammates to focus on injects with confidence.
