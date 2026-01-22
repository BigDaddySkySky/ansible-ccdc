# Roles

This directory contains reusable Ansible roles used by the competition runbook.

Roles are grouped by function and invoked by numbered playbooks in `playbooks/`.

---

## Critical Path

- `common_preflight`  
  Pre-flight checks before changes

- `ssh_hardening`  
  Secure SSH access and authentication

- `firewall`  
  Host-based firewall configuration

- `auditd`  
  Host monitoring and audit logging

- `common_notify`  
  Automation event notifications

- `common_validation`  
  Post-change validation checks

---

## Splunk

- `splunk_configure`  
  Initial Splunk server configuration

- `splunk_harden`  
  Splunk service hardening

- `splunk_content`  
  Dashboard and UI content deployment

- `splunk_universal_forwarder`  
  Endpoint forwarder installation and configuration

---

## Notes

- Each role contains a concise README describing intent and scope
- Roles are designed to be idempotent and safe for competition use
- Do not modify role behavior during competition unless directed by White Team
