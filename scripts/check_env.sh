#!/usr/bin/env bash

# ================== PURPOSE ==================
# Verify Python, Ansible, and vault environment
# before running playbooks. Ensures inventory
# and vault files are present and encrypted,
# and tests connectivity to all hosts.
#
# USAGE:
#   ./scripts/check_env.sh
#
# NOTES:
# - Safe to run anytime; does not modify state.
# - Exits non-zero if environment is misconfigured.
# =============================================

set -euo pipefail

echo "== Checking Python and Ansible =="
python3 --version
ansible --version

echo "== Checking vault password file =="
VAULT_PASS_FILE="$(ansible-config dump | awk -F'= ' '/DEFAULT_VAULT_PASSWORD_FILE/ {print $2} ' | xargs)"
echo "Vault password file: ${VAULT_PASS_FILE:-unset}"
[[ -n "$VAULT_PASS_FILE" && -f "$VAULT_PASS_FILE" ]] || { echo "Missing vault password file"; exit 1; }

echo "== Checking inventory and connectivity =="
[[ -f inventory.ini ]] || { echo "Missing inventory.ini"; exit 1; }
ansible all 0m ping -o || { echo "Ping failed"; exit1; }

echo "== Verify vaults are encrypted =="
for f in group_vars/**/vault.yml group_vars/*vault.yml host_vars/*vault.yml; do
    [[ -f "$f" ]] || continue
    head -n 1 "$f" | grep -q "ANSIBLE_VAULT" || { echo "Unencrypted vault: $f"; exit 1; }
done

echo "Everything checks out!"