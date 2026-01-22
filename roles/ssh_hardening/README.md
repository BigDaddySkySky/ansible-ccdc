# ssh_hardening

Purpose:
- Secure SSH access on competition hosts
- Enforce key-based authentication and reduce brute-force risk

Used by:
- `critical-path` playbook

Changes:
- Hardens sshd configuration
- Disables root SSH login and password authentication
- Configures fail2ban for SSH abuse
- Validates configuration before applying

Key Inputs (vars):
- ssh_hardening_disable_password_auth
- ssh_hardening_lock_root_account
- ssh_hardening_enable_fail2ban
- ssh_hardening_force_no_keys

Notes:
- SSH keys must be deployed before running
- Do not change SSH port (scoring dependency)
- Test on a single host before broad deployment

