#!/usr/bin/env bash
set -euo pipefail

echo "=== Password Configuration Validator ==="
echo ""

ERRORS=0

# Check that host_vars exist for all hosts
HOSTS=(ubuntu_ecom fedora_webmail splunk ubuntu_wks dc01 web01 ftp01 windows11_wks pa01 ftd01 vyos)

echo "1. Checking host_vars files exist..."
for host in "${HOSTS[@]}"; do
    if [[ -f "host_vars/${host}.yml" ]]; then
        echo "  ✓ host_vars/${host}.yml"
    else
        echo "  ✗ MISSING: host_vars/${host}.yml"
        ((ERRORS++))
    fi
done

echo ""
echo "2. Checking host_vars are encrypted..."
for host in "${HOSTS[@]}"; do
    if [[ -f "host_vars/${host}.yml" ]]; then
        if head -n 1 "host_vars/${host}.yml" | grep -q 'ANSIBLE_VAULT'; then
            echo "  ✓ ${host}.yml is encrypted"
        else
            echo "  ✗ ${host}.yml is NOT encrypted!"
            ((ERRORS++))
        fi
    fi
done

echo ""
echo "3. Checking for old group password variables..."
if grep -q 'vault_linux_ssh_pass' group_vars/linux.yml 2>/dev/null; then
    echo "  ✗ Found old vault_linux_ssh_pass in group_vars/linux.yml"
    echo "    (Should be removed - using host_vars now)"
    ((ERRORS++))
else
    echo "  ✓ No old password variables in group_vars/linux.yml"
fi

if grep -q 'vault_windows_admin_pass' group_vars/windows.yml 2>/dev/null; then
    echo "  ✗ Found old vault_windows_admin_pass in group_vars/windows.yml"
    echo "    (Should be removed - using host_vars now)"
    ((ERRORS++))
else
    echo "  ✓ No old password variables in group_vars/windows.yml"
fi

echo ""
echo "4. Verifying pass_reset_v2.yml exists..."
if [[ -f "playbooks/pass_reset_v2.yml" ]]; then
    echo "  ✓ playbooks/pass_reset_v2.yml found"
else
    echo "  ✗ playbooks/pass_reset_v2.yml missing"
    ((ERRORS++))
fi

echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo "✅ Password configuration validated successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Test connectivity: ansible all -m ping"
    echo "  2. Verify variables: ansible-inventory --list"
    echo "  3. Dry-run reset: ansible-playbook playbooks/pass_reset_v2.yml --check"
else
    echo "❌ Found $ERRORS errors - fix before competition!"
fi