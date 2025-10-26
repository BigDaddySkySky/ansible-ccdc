#!/usr/bin/env bash

# ================== PURPOSE ==================
# Safely edit an Ansible vault file. Ensures
# vault password file is configured, opens the
# file for editing, and re-encrypts if needed.
#
# USAGE:
#   ./scripts/vault_edit.sh group_vars/linux/vault.yml
#
# NOTES:
# - Requires ansible-vault and vault password file.
# - Confirms file remains encrypted after edit.
# - Shows git status to prevent committing plaintext.
# =============================================

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <vault_file.yml>"
    exit 1
fi

VAULT_FILE="$1"

# Confirm the file exists
if [[ ! -f "$VAULT_FILE" ]]; then
    echo "Error: $VAULT_FILE not found."
    exit 1
fi

# Confirm vault password file has been configured
VAULT_PASS_FILE="$(ansible-config dump | awk -F'= ' '/DEFAULT_VAULT_PASSWORD_FILE / {print $2}' | xargs)"
if [[ ! -f "$VAULT_PASS_FILE" ]]; then
    echo "Error: Vault password file not found at : $VAULT_PASS_FILE"
    echo "Set it in ansible.cfg (vault_password_file = ~/.vault_pass)"
    exit 1
fi

# Safely edit the vault file
echo "Opening vaut for editing:" $VAULT_FILE
ansible-vault edit "$VAULT_FILE"

# Verify that the file has been encrypted (Should detect $ANSIBLE_VAULT;1.1 header)
if head -n 1 "$VAULT_FILE" | grep -q "ANIBLE_VAULT" ; then
    echo "Re-encryption confirmed for $VAULT_FILE"
else
    echo "Warning: $VAULT_FILE appears unencrypted. Re-encrypting..."
    ansible-vault encrypt "$VAULT_FILE"
fi

# show git status to avoid commiting decrypted files
git status --short
echo "Reminder: Confirm only encrypted vault files are staged before commit."