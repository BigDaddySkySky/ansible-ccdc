#!/usr/bin/env bash

# ================== PURPOSE ==================
# Quick Installation Script for Hardened Detection System
# - Backs up existing files
# - Copies new files to repository
# - Sets proper permissions
# - Runs validation
# =============================================

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  CCDC Detection System - Hardened Installation        ║${NC}"
echo -e "${BLUE}║  Version: 1.0.0-hardened                               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running in correct directory
if [[ ! -f "inventory.ini" ]]; then
    echo -e "${RED}ERROR: Must run from ansible repository root${NC}"
    echo "Expected to find inventory.ini in current directory"
    exit 1
fi

echo -e "${YELLOW}Step 1: Creating backup...${NC}"
BACKUP_FILE="backup_detection_$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf "$BACKUP_FILE" \
    roles/intrusion_detection/ \
    playbooks/deploy_detection.yml \
    playbooks/check_intrusions.yml \
    playbooks/test_alerts.yml \
    2>/dev/null || echo "Some files not found (OK if new installation)"

echo -e "${GREEN}✓ Backup created: $BACKUP_FILE${NC}"
echo ""

echo -e "${YELLOW}Step 2: Checking for outputs directory...${NC}"
if [[ ! -d "/mnt/user-data/outputs" ]]; then
    echo -e "${RED}ERROR: Outputs directory not found${NC}"
    echo "Expected: /mnt/user-data/outputs"
    echo "Please ensure hardened files are extracted"
    exit 1
fi
echo -e "${GREEN}✓ Outputs directory found${NC}"
echo ""

echo -e "${YELLOW}Step 3: Installing hardened files...${NC}"

# Copy role files
echo "  → Installing role files..."
mkdir -p roles/intrusion_detection/{files,templates,tasks,handlers}
cp -v /mnt/user-data/outputs/roles/intrusion_detection/files/*.py \
    roles/intrusion_detection/files/
cp -v /mnt/user-data/outputs/roles/intrusion_detection/templates/*.j2 \
    roles/intrusion_detection/templates/
cp -v /mnt/user-data/outputs/roles/intrusion_detection/tasks/*.yml \
    roles/intrusion_detection/tasks/
cp -v /mnt/user-data/outputs/roles/intrusion_detection/handlers/*.yml \
    roles/intrusion_detection/handlers/

# Copy playbooks
echo "  → Installing playbooks..."
mkdir -p playbooks
cp -v /mnt/user-data/outputs/playbooks/*.yml playbooks/

# Copy scripts
echo "  → Installing scripts..."
mkdir -p scripts
cp -v /mnt/user-data/outputs/scripts/*.sh scripts/

# Copy documentation
echo "  → Installing documentation..."
cp -v /mnt/user-data/outputs/*.md .

echo -e "${GREEN}✓ All files installed${NC}"
echo ""

echo -e "${YELLOW}Step 4: Setting permissions...${NC}"
chmod +x scripts/*.sh
chmod +x roles/intrusion_detection/files/*.py
echo -e "${GREEN}✓ Permissions set${NC}"
echo ""

echo -e "${YELLOW}Step 5: Verifying file structure...${NC}"
REQUIRED_FILES=(
    "roles/intrusion_detection/files/discord_alert.py"
    "roles/intrusion_detection/files/alert_retry_daemon.py"
    "roles/intrusion_detection/templates/log_watcher.py.j2"
    "roles/intrusion_detection/templates/honeypot_watcher.sh.j2"
    "playbooks/check_detection_status.yml"
    "playbooks/restart_detection.yml"
    "playbooks/test_detection_system.yml"
    "scripts/validate_detection.sh"
    "scripts/emergency_detection_restart.sh"
    "IMPLEMENTATION_GUIDE.md"
    "QUICK_REFERENCE.md"
)

MISSING=0
for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo -e "  ${RED}✗ Missing: $file${NC}"
        ((MISSING++))
    fi
done

if [[ $MISSING -eq 0 ]]; then
    echo -e "${GREEN}✓ All required files present${NC}"
else
    echo -e "${RED}✗ Missing $MISSING files${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}Step 6: Checking Python dependencies...${NC}"
if python3 -c "import fcntl" 2>/dev/null; then
    echo -e "${GREEN}✓ fcntl module available${NC}"
else
    echo -e "${YELLOW}! fcntl not available (OK on Windows, will use fallback)${NC}"
fi
echo ""

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Installation Complete!                                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo ""
echo -e "  1. Run validation:"
echo -e "     ${BLUE}./scripts/validate_detection.sh${NC}"
echo ""
echo -e "  2. Review implementation guide:"
echo -e "     ${BLUE}cat IMPLEMENTATION_GUIDE.md${NC}"
echo ""
echo -e "  3. Deploy to test host:"
echo -e "     ${BLUE}ansible-playbook playbooks/deploy_detection.yml --limit ubuntu_ecom${NC}"
echo ""
echo -e "  4. Run tests:"
echo -e "     ${BLUE}ansible-playbook playbooks/test_detection_system.yml --limit ubuntu_ecom${NC}"
echo ""
echo -e "${YELLOW}Backup saved to: $BACKUP_FILE${NC}"
echo ""