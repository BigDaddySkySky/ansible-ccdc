#!/usr/bin/env bash

# ================== PURPOSE ==================
# Quick AD Password Reset for Competition
# - Runs the full playbook with sane defaults
# - Logs passwords for team reference
# - Minimal prompts for speed
# =============================================
# USAGE:
#   ./scripts/reset_ad_passwords.sh
#   ./scripts/reset_ad_passwords.sh --no-force-change

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  AD Password Reset - Competition Quick Script         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Parse arguments
FORCE_CHANGE="true"
SKIP_CONFIRM="false"

while [[ $# -gt 0 ]]; do
  case $1 in
    --no-force-change)
      FORCE_CHANGE="false"
      shift
      ;;
    --yes|-y)
      SKIP_CONFIRM="true"
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Usage: $0 [--no-force-change] [--yes]"
      exit 1
      ;;
  esac
done

# Check we're in the right directory
if [[ ! -f "inventory.ini" ]]; then
    echo -e "${RED}ERROR: Must run from ansible repository root${NC}"
    echo "Expected to find inventory.ini in current directory"
    exit 1
fi

# Check playbook exists
if [[ ! -f "playbooks/ad_password_reset.yml" ]]; then
    echo -e "${RED}ERROR: Playbook not found${NC}"
    echo "Expected: playbooks/ad_password_reset.yml"
    exit 1
fi

# Display configuration
echo -e "${YELLOW}Configuration:${NC}"
echo "  Force password change at logon: ${FORCE_CHANGE}"
echo "  Target: AD/DNS servers in inventory"
echo ""

# Confirm unless --yes
if [[ "$SKIP_CONFIRM" != "true" ]]; then
    echo -e "${YELLOW}⚠️  This will change passwords for ALL non-admin AD users!${NC}"
    echo ""
    echo "Excluded:"
    echo "  - Administrator, Guest, krbtgt, sysadmin"
    echo "  - Members of Domain Admins, Enterprise Admins"
    echo ""
    read -p "Continue? (yes/no): " -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Run playbook
echo -e "${GREEN}Running password reset...${NC}"
echo ""

if [[ "$FORCE_CHANGE" == "true" ]]; then
    ansible-playbook playbooks/ad_password_reset.yml \
        --skip-tags confirm \
        -e "force_change_at_logon=true"
else
    ansible-playbook playbooks/ad_password_reset.yml \
        --skip-tags confirm \
        -e "force_change_at_logon=false"
fi

EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ Password Reset Complete                            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}NEXT STEPS:${NC}"
    echo "  1. Find password log: ls -lh playbooks/password_logs/"
    echo "  2. Secure the file: chmod 600 playbooks/password_logs/ad_passwords_*.txt"
    echo "  3. Distribute passwords to team"
    echo "  4. DELETE password log after distribution"
    echo ""
    echo -e "${YELLOW}To view passwords:${NC}"
    echo "  cat playbooks/password_logs/ad_passwords_*.txt"
    echo ""
    echo -e "${YELLOW}To print distribution sheet:${NC}"
    echo "  cat playbooks/password_logs/ad_passwords_*_distribution.txt"
    echo ""
else
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ❌ Password Reset Failed                              ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Check the error output above for details."
    echo ""
    echo "Common issues:"
    echo "  - AD server not reachable"
    echo "  - Insufficient permissions"
    echo "  - WinRM not configured"
    echo ""
    exit 1
fi