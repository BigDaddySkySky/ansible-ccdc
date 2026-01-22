# Vaulted Variables – host_vars

This directory contains encrypted Ansible Vault files.
Variables defined here are scoped per host.

## Stored Here
- Passwords post-rotation
- Host priority for scoring
- Per-host role declarations

## Declared Variables

### Ubuntu – Ecom
- vault_os_become_password
- vault_host_role
- vault_host_priority

### Splunk
- vault_os_root_initial_password
- vault_os_sysadmin_initial_password
- vault_os_become_password
- vault_os_root_password
- vault_os_sysadmin_password
- vault_splunk_admin_initial_password
- vault_splunk_admin_password

### Fedora – Webmail
- vault_os_become_password
- vault_host_role
- vault_host_priority

### Ubuntu – Workstation
- vault_os_become_password
- vault_host_role
- vault_host_priority

## Notes
- Most variables track credentials after password rotation
- Values are intentionally obfuscated to limit red-team reconnaissance
