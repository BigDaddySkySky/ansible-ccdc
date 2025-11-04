#!/usr/bin/env bash
# Sprint 0.5 Testing Script

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SPRINT="0.5"

echo -e "${YELLOW}=== Testing Sprint ${SPRINT} Deliverables ===${NC}"
echo ""

PASS=0
FAIL=0

test_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASS++))
}

test_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAIL++))
}

# Test 1: Directory structure
echo -e "${YELLOW}Test 1: Repository structure${NC}"
for dir in inventory group_vars playbooks roles scripts docs; do
    if [[ -d "$dir" ]]; then
        test_pass "$dir/ exists"
    else
        test_fail "$dir/ missing"
    fi
done

# Test 2: Required files
echo ""
echo -e "${YELLOW}Test 2: Required files${NC}"
REQUIRED_FILES=(
    "README.md"
    "INVITATIONAL_POSTMORTEM.md"
    "inventory/staging.ini"
    "playbooks/00-hello-world.yml"
    "playbooks/01-validate-environment.yml"
    "scripts/bootstrap.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        test_pass "$file"
    else
        test_fail "$file"
    fi
done

# Test 3: Bootstrap script is executable
echo ""
echo -e "${YELLOW}Test 3: Script permissions${NC}"
if [[ -x "scripts/bootstrap.sh" ]]; then
    test_pass "bootstrap.sh is executable"
else
    test_fail "bootstrap.sh not executable"
fi

# Test 4: Ansible syntax
echo ""
echo -e "${YELLOW}Test 4: Playbook syntax${NC}"
if command -v ansible-playbook &>/dev/null; then
    for playbook in playbooks/*.yml; do
        if ansible-playbook "$playbook" --syntax-check &>/dev/null; then
            test_pass "$(basename "$playbook") syntax OK"
        else
            test_fail "$(basename "$playbook") has syntax errors"
        fi
    done
else
    test_fail "ansible-playbook not found (run ./scripts/bootstrap.sh)"
fi

# Test 5: Inventory validation
echo ""
echo -e "${YELLOW}Test 5: Inventory${NC}"
if command -v ansible-inventory &>/dev/null; then
    if ansible-inventory -i inventory/staging.ini --list &>/dev/null; then
        test_pass "staging.ini is valid"
    else
        test_fail "staging.ini has errors"
    fi
else
    test_fail "ansible-inventory not found"
fi

# Summary
echo ""
echo -e "${YELLOW}========================================${NC}"
if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}✅ All tests passed! ($PASS/$((PASS+FAIL)))${NC}"
    echo ""
    echo "Sprint 0.5 is complete! Next steps:"
    echo "  1. Set up VMs: ./scripts/setup-vms.sh"
    echo "  2. Test hello-world: ansible-playbook playbooks/00-hello-world.yml"
    echo "  3. Start Sprint 1 when ready"
    exit 0
else
    echo -e "${RED}❌ Some tests failed ($FAIL failures, $PASS passes)${NC}"
    echo ""
    echo "Fix the issues above before proceeding."
    exit 1
fi
