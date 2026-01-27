#!/usr/bin/env bash
# ============================================================
# Preflight (Competition-Safe)
#
# Purpose:
#   Fast, read-only checks before running playbooks.
#   No secrets printed. No repo mutation. No lab assumptions.
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

pass() { echo -e "${GREEN}✓${NC} $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}✗${NC} $1"; FAIL=$((FAIL+1)); }

echo -e "${YELLOW}=== Preflight Checks ===${NC}"
echo ""

# Check: required directories
echo -e "${YELLOW}Check: Repository structure${NC}"
REQUIRED_DIRS=(inventory group_vars playbooks roles scripts)
for dir in "${REQUIRED_DIRS[@]}"; do
  if [[ -d "$dir" ]]; then
    pass "dir exists: $dir"
  else
    fail "dir missing: $dir"
  fi
done

# Check: required operator files
echo ""
echo -e "${YELLOW}Check: Required files${NC}"
REQUIRED_FILES=(
  "README.md"
  "inventory/staging.ini"
  "inventory/production.ini"
  "scripts/bootstrap.sh"
  "playbooks/02-critical-path.yml"
)
for file in "${REQUIRED_FILES[@]}"; do
  [[ -f "$file" ]] && pass "$file" || fail "$file missing"
done

# Check: bootstrap executable
echo ""
echo -e "${YELLOW}Check: Script permissions${NC}"
[[ -x "scripts/bootstrap.sh" ]] && pass "scripts/bootstrap.sh executable" \
  || fail "scripts/bootstrap.sh not executable (run: chmod +x scripts/bootstrap.sh)"
[[ -x "scripts/preflight.sh" ]] && pass "scripts/preflight.sh executable" \
  || fail "scripts/preflight.sh not executable (run: chmod +x scripts/preflight.sh)"

# Check: tools present
echo ""
echo -e "${YELLOW}Check: Tooling${NC}"
command -v ansible-playbook &>/dev/null && pass "ansible-playbook found" \
  || fail "ansible-playbook not found (run: ./scripts/bootstrap.sh)"
command -v ansible-inventory &>/dev/null && pass "ansible-inventory found" \
  || fail "ansible-inventory not found (run: ./scripts/bootstrap.sh)"

# Check: vault password file exists (do NOT print contents)
echo ""
echo -e "${YELLOW}Check: Vault access${NC}"
VAULT_FILE="$HOME/.vault_pass"
if [[ -f "$VAULT_FILE" ]]; then
  pass "Vault password file present (~/.vault_pass)"
else
  fail "Missing ~/.vault_pass (create it before running vaulted playbooks)"
fi

# Check: playbook syntax (read-only)
echo ""
echo -e "${YELLOW}Check: Playbook syntax${NC}"
for playbook in playbooks/*.yml; do
  [[ -f "$playbook" ]] || continue
  if ansible-playbook "$playbook" --syntax-check &>/dev/null; then
    pass "$(basename "$playbook") syntax OK"
  else
    fail "$(basename "$playbook") syntax ERROR"
  fi
done

# Check: inventory parses
echo ""
echo -e "${YELLOW}Check: Inventory parsing${NC}"
if ansible-inventory -i inventory/staging.ini --list &>/dev/null; then
  pass "inventory/staging.ini parses"
else
  fail "inventory/staging.ini parse error"
fi

# Summary
echo ""
echo -e "${YELLOW}------------------------------------------${NC}"
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}✅ Preflight passed ($PASS checks)${NC}"
  echo ""
  echo "Next step:"
  echo "  ansible-playbook -i inventory/staging.ini playbooks/02-critical-path.yml"
  exit 0
else
  echo -e "${RED}❌ Preflight failed ($FAIL failures, $PASS passes)${NC}"
  echo "Fix failures before running competition playbooks."
  exit 1
fi
