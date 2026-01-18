#!/usr/bin/env bash
# Comprehensive Vault Diagnostic
# Shows EXACTLY what's wrong with vault configuration

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   VAULT CONFIGURATION DIAGNOSTIC        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# Check 1: Vault password file
echo -e "${YELLOW}═══ CHECK 1: Vault Password File ═══${NC}"
if [[ -f "$HOME/.vault_pass" ]]; then
    echo -e "${GREEN}✓${NC} File exists: $HOME/.vault_pass"
    echo "  Contents: $(cat $HOME/.vault_pass)"
    echo "  Permissions: $(stat -c '%a' $HOME/.vault_pass)"
else
    echo -e "${RED}✗ MISSING: $HOME/.vault_pass${NC}"
fi

# Check 2: ansible.cfg
echo ""
echo -e "${YELLOW}═══ CHECK 2: ansible.cfg Configuration ═══${NC}"
if grep -q "vault_password_file" ansible.cfg 2>/dev/null; then
    echo -e "${GREEN}✓${NC} vault_password_file configured"
    grep "vault_password_file" ansible.cfg | sed 's/^/  /'
else
    echo -e "${RED}✗ NOT CONFIGURED in ansible.cfg${NC}"
fi

# Check 3: Vault files exist and encryption status
echo ""
echo -e "${YELLOW}═══ CHECK 3: Vault File Status ═══${NC}"

VAULT_FILES=(
    "group_vars/all/vault.yml"
    "host_vars/ubuntu_ecom_vm/vault.yml"
    "host_vars/fedora_webmail_vm/vault.yml"
)

for vault_file in "${VAULT_FILES[@]}"; do
    echo ""
    echo "File: $vault_file"
    if [[ -f "$vault_file" ]]; then
        echo -e "  ${GREEN}✓${NC} Exists"
        
        # Check encryption
        FIRST_LINE=$(head -1 "$vault_file")
        if [[ "$FIRST_LINE" == '$ANSIBLE_VAULT;'* ]]; then
            echo -e "  ${GREEN}✓${NC} Encrypted"
        else
            echo -e "  ${RED}✗ NOT ENCRYPTED (plaintext)${NC}"
            echo "  First line: $FIRST_LINE"
        fi
        
        # Try to decrypt
        if ansible-vault view "$vault_file" > /tmp/vault_test_$$.txt 2>&1; then
            echo -e "  ${GREEN}✓${NC} Decryption successful"
            
            # Check for vault_default_password in global vault
            if [[ "$vault_file" == "group_vars/all/vault.yml" ]]; then
                if grep -q "vault_default_password" /tmp/vault_test_$$.txt; then
                    echo -e "  ${GREEN}✓${NC} Contains vault_default_password"
                    grep "vault_default_password" /tmp/vault_test_$$.txt | sed 's/^/    /'
                else
                    echo -e "  ${RED}✗ MISSING vault_default_password${NC}"
                fi
            fi
            
            # Check for vault_host_password in host vaults
            if [[ "$vault_file" =~ host_vars ]]; then
                if grep -q "vault_host_password" /tmp/vault_test_$$.txt; then
                    echo -e "  ${GREEN}✓${NC} Contains vault_host_password"
                    grep "vault_host_password" /tmp/vault_test_$$.txt | sed 's/^/    /'
                else
                    echo -e "  ${RED}✗ MISSING vault_host_password${NC}"
                fi
            fi
            
            rm -f /tmp/vault_test_$$.txt
        else
            echo -e "  ${RED}✗ Decryption FAILED${NC}"
            cat /tmp/vault_test_$$.txt | sed 's/^/    /'
            rm -f /tmp/vault_test_$$.txt
        fi
    else
        echo -e "  ${RED}✗ DOES NOT EXIST${NC}"
    fi
done

# Check 4: Variable loading test
echo ""
echo -e "${YELLOW}═══ CHECK 4: Variable Loading Test ═══${NC}"

# Test global variable
echo ""
echo "Validating: ansible localhost -m debug -a \"var=vault_default_password\""
if ansible localhost -m debug -a "var=vault_default_password" 2>&1 | grep -q "changeme"; then
    echo -e "${GREEN}✓${NC} vault_default_password loads correctly"
    ansible localhost -m debug -a "var=vault_default_password" 2>&1 | grep -A1 "vault_default_password" | sed 's/^/  /'
else
    echo -e "${RED}✗ vault_default_password is UNDEFINED${NC}"
    ansible localhost -m debug -a "var=vault_default_password" 2>&1 | tail -5 | sed 's/^/  /'
fi

# Test host variable
echo ""
echo "Validating: ansible ubuntu_ecom_vm -m debug -a \"var=vault_host_password\""
if ansible ubuntu_ecom_vm -m debug -a "var=vault_host_password" 2>&1 | grep -q "Ub2025"; then
    echo -e "${GREEN}✓${NC} vault_host_password loads correctly"
    ansible ubuntu_ecom_vm -m debug -a "var=vault_host_password" 2>&1 | grep -A1 "vault_host_password" | sed 's/^/  /'
else
    echo -e "${RED}✗ vault_host_password is UNDEFINED${NC}"
    ansible ubuntu_ecom_vm -m debug -a "var=vault_host_password" 2>&1 | tail -5 | sed 's/^/  /'
fi

# Check 5: Inventory configuration
echo ""
echo -e "${YELLOW}═══ CHECK 5: Inventory Configuration ═══${NC}"
echo ""
echo "Current inventory vars for linux_servers:"
grep -A5 "\[linux_servers:vars\]" inventory/staging.ini | sed 's/^/  /'

# Check 6: Show what ansible sees
echo ""
echo -e "${YELLOW}═══ CHECK 6: Ansible Variable Resolution ═══${NC}"
echo ""
echo "What Ansible sees for ubuntu_ecom_vm:"
ansible-inventory --host ubuntu_ecom_vm 2>&1 | grep -E "(ansible_password|ansible_become_password|vault_)" | sed 's/^/  /'

# Summary
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   DIAGNOSTIC COMPLETE                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""
echo "If you see UNDEFINED errors above, likely causes:"
echo ""
echo "1. Vault files not encrypted:"
echo "   → Run: ansible-vault encrypt group_vars/all/vault.yml"
echo ""
echo "2. Wrong vault password:"
echo "   → Check: cat ~/.vault_pass"
echo "   → Should be: changeme"
echo ""
echo "3. Variables missing from vault files:"
echo "   → Run: ansible-vault edit group_vars/all/vault.yml"
echo "   → Ensure it contains: vault_default_password: \"changeme\""
echo ""
echo "4. ansible.cfg not configured:"
echo "   → Add: vault_password_file = ~/.vault_pass"
echo ""
echo "Run the detailed view to see vault contents:"
echo "  ansible-vault view group_vars/all/vault.yml"
echo ""
