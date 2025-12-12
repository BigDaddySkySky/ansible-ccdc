# Role: ssh_hardening

Purpose
- Lock down SSH while keeping access: disable root login, enforce key auth, strengthen ciphers/MACs/KEX, and enable fail2ban without changing ports.

When to Run
- After SSH keys deployed; before firewall hardening; part of `playbooks/30-hardening-main.yml`.

Variables Required
- `ssh_hardening_disable_password_auth` (default true), `ssh_hardening_lock_root_account` (true), `ssh_hardening_force_no_keys` (false), `ssh_hardening_enable_fail2ban` (true).
- Security tuning: `ssh_hardening_max_auth_tries`, `ssh_hardening_login_grace_time`, cipher/MAC/KEX lists.
- Uses inventory/become vars and vault passwords.

Dependencies
- SSH keys present on hosts; sudo access; fail2ban package availability.

Run Steps
1) Confirm keys work (`ansible all -m ping`).
2) Snapshot VMs if possible.
3) `ansible-playbook playbooks/30-hardening-main.yml --tags ssh` (or full stack).

Validation (Scoring-Aligned)
- Key auth: `ssh -i ~/.ssh/ccdc_rsa <user>@<host>` works.
- Root login blocked: `ssh root@<host>` denied.
- Fail2ban: `fail2ban-client status sshd` shows jail active.
- Scored services: verify 22/80/443/25/110/21/53 and ICMP still reachable.

White Team Visibility
- No port/IP/hostname changes; only sshd config and fail2ban jail; keeps port 22 open per scoring.

Inject Impact
- Reduces brute-force noise automatically, freeing teammates to handle injects and triage.
