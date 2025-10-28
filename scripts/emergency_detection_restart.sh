#!/usr/bin/env bash

# ================== PURPOSE ==================
# Emergency Detection System Restart Script
# - Quick command-line tool for competition
# - Restarts all detection services
# - Validates services started correctly
# =============================================
# USAGE:
#   ./scripts/emergency_detection_restart.sh [hostname]
#   ./scripts/emergency_detection_restart.sh ubuntu_ecom
#   ./scripts/emergency_detection_restart.sh all

set -euo pipefail

INVENTORY="${INVENTORY:-inventory.ini}"
TARGET="${1:-all}"

echo "=== Emergency Detection Restart ==="
echo "Target: $TARGET"
echo "Time: $(date)"
echo ""

if [[ "$TARGET" == "all" ]]; then
    echo "⚠️  Restarting detection on ALL Linux hosts..."
    ansible-playbook playbooks/restart_detection.yml -i "$INVENTORY"
else
    echo "⚠️  Restarting detection on $TARGET..."
    ansible-playbook playbooks/restart_detection.yml -i "$INVENTORY" --limit "$TARGET"
fi

echo ""
echo "✅ Restart complete!"
echo ""
echo "Quick status check:"
ansible linux -i "$INVENTORY" ${TARGET:+--limit "$TARGET"} -m shell -a "systemctl is-active ccdc-log-watcher ccdc-honeypot-watcher ccdc-alert-retry" -o

echo ""
echo "To verify full status, run:"
echo "  ansible-playbook playbooks/check_detection_status.yml ${TARGET:+--limit "$TARGET"}"