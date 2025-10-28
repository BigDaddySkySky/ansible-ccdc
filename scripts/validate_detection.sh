#!/usr/bin/env bash

# ================== PURPOSE ==================
# Validate Detection System Configuration
# - Pre-competition validation script
# - Checks all dependencies and configurations
# - Verifies webhook connectivity
# =============================================
# USAGE:
#   ./scripts/validate_detection.sh

set -euo pipefail

echo "=== CCDC Detection System Validation ==="
echo "Time: $(date)"
echo ""

ERRORS=0
WARNINGS=0

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}❌ ERROR:${NC} $1"
    ((ERRORS++))
}

warn() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
    ((WARNINGS++))
}

success() {
    echo -e "${GREEN}✅${NC} $1"
}

echo "1. Checking Python environment..."
if command -v python3 &> /dev/null; then
    PY_VERSION=$(python3 --version)
    success "Python found: $PY_VERSION"
else
    error "Python 3 not found"
fi

echo ""
echo "2. Checking Ansible installation..."
if command -v ansible &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -1)
    success "Ansible found: $ANSIBLE_VERSION"
else
    error "Ansible not found"
fi

echo ""
echo "3. Checking inventory file..."
if [[ -f inventory.ini ]]; then
    success "Inventory file exists"
    
    LINUX_HOSTS=$(grep -A100 '^\[linux\]' inventory.ini | grep -v '^\[' | grep -v '^#' | grep -v '^$' | wc -l)
    echo "   Linux hosts defined: $LINUX_HOSTS"
else
    error "inventory.ini not found"
fi

echo ""
echo "4. Checking vault configuration..."
VAULT_PASS_FILE=$(ansible-config dump | awk -F'= ' '/DEFAULT_VAULT_PASSWORD_FILE/ {print $2}' | xargs)
if [[ -n "$VAULT_PASS_FILE" && -f "$VAULT_PASS_FILE" ]]; then
    success "Vault password file configured: $VAULT_PASS_FILE"
else
    error "Vault password file not found"
fi

echo ""
echo "5. Checking Discord webhook..."
if ansible-inventory -i inventory.ini --list | grep -q discord_webhook_url; then
    success "Discord webhook configured in inventory"
    
    # Try to extract webhook URL (this will fail if encrypted in vault)
    WEBHOOK=$(ansible all -i inventory.ini -m debug -a "var=discord_webhook_url" --limit localhost 2>/dev/null | grep -oP 'https://discord.com/api/webhooks/[^"]+' || echo "")
    
    if [[ -n "$WEBHOOK" ]]; then
        echo "   Testing webhook connectivity..."
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$WEBHOOK" \
            -H "Content-Type: application/json" \
            -d '{"content":"🧪 CCDC Detection validation test"}' || echo "000")
        
        if [[ "$HTTP_CODE" == "204" ]] || [[ "$HTTP_CODE" == "200" ]]; then
            success "Webhook test successful (HTTP $HTTP_CODE)"
        else
            error "Webhook test failed (HTTP $HTTP_CODE)"
        fi
    else
        warn "Could not extract webhook URL for testing (may be in vault)"
    fi
else
    error "Discord webhook not configured"
fi

echo ""
echo "6. Checking detection role files..."
REQUIRED_FILES=(
    "roles/intrusion_detection/files/discord_alert.py"
    "roles/intrusion_detection/files/alert_retry_daemon.py"
    "roles/intrusion_detection/templates/log_watcher.py.j2"
    "roles/intrusion_detection/templates/honeypot_watcher.sh.j2"
    "roles/intrusion_detection/tasks/configure_auditd.yml"
    "roles/intrusion_detection/tasks/install_watchers.yml"
    "roles/intrusion_detection/tasks/setup_honeypots.yml"
    "roles/intrusion_detection/tasks/deploy_cron.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        success "$file"
    else
        error "Missing file: $file"
    fi
done

echo ""
echo "7. Checking detection playbooks..."
PLAYBOOKS=(
    "playbooks/deploy_detection.yml"
    "playbooks/check_detection_status.yml"
    "playbooks/restart_detection.yml"
    "playbooks/test_detection_system.yml"
)

for playbook in "${PLAYBOOKS[@]}"; do
    if [[ -f "$playbook" ]]; then
        success "$playbook"
    else
        error "Missing playbook: $playbook"
    fi
done

echo ""
echo "8. Checking host connectivity..."
if ansible linux -i inventory.ini -m ping -o &> /dev/null; then
    success "All Linux hosts reachable"
else
    error "Some Linux hosts unreachable"
    echo "   Run: ansible linux -m ping"
fi

echo ""
echo "9. Checking existing detection deployment..."
DEPLOYED=$(ansible linux -i inventory.ini -m shell -a "systemctl is-active ccdc-log-watcher 2>/dev/null || echo 'not-deployed'" -o 2>/dev/null | grep -c "active" || echo "0")
echo "   Hosts with detection deployed: $DEPLOYED"

if [[ $DEPLOYED -gt 0 ]]; then
    success "Detection already deployed on some hosts"
else
    warn "Detection not yet deployed (run deploy_detection.yml)"
fi

echo ""
echo "10. Syntax checking playbooks..."
for playbook in "${PLAYBOOKS[@]}"; do
    if [[ -f "$playbook" ]]; then
        if ansible-playbook "$playbook" --syntax-check &> /dev/null; then
            success "Syntax OK: $playbook"
        else
            error "Syntax error in: $playbook"
        fi
    fi
done

echo ""
echo "=== Validation Summary ==="
echo -e "Errors: ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

if [[ $ERRORS -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}✅ System ready for detection deployment!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Deploy detection: ansible-playbook playbooks/deploy_detection.yml"
    echo "  2. Test system: ansible-playbook playbooks/test_detection_system.yml"
    echo "  3. Check status: ansible-playbook playbooks/check_detection_status.yml"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Please fix errors before deploying detection system${NC}"
    exit 1
fi