# Scripts Quick Reference

Purpose
- One-liners to prep the control node and diagnose issues quickly.

Scripts
- `bootstrap.sh`: create venv, install collections/roles, sanity-check Ansible.
- `setup-ssh-keys.sh`: push `~/.ssh/ccdc_rsa.pub` to hosts using known passwords.
- `diagnose-vault.sh`: validate vault file presence/decryption.
- `diagnose-splunk.sh`: gather Splunk status/logs on splunk_vm.
- `test-sprint.sh`: runs validation smoke for scored services.

Usage
- `./scripts/bootstrap.sh && source .venv/bin/activate`
- Run diagnostics with `bash scripts/diagnose-*.sh` (read-only except setup-ssh-keys writes authorized_keys).

Validation
- `echo $VIRTUAL_ENV` after bootstrap; `ansible --version`; `ansible-galaxy collection list` for required collections.

White Team Visibility
- Scripts act on control node or push keys; no network/IP changes; setup-ssh-keys only adds authorized_keys.

Inject Impact
- Faster prep/triage so responders can pivot to inject tasks sooner.
