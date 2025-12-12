#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}═══ SPLUNK DIAGNOSTIC ═══${NC}"
echo ""

# Check if Splunk is installed
echo "1. Checking Splunk installation..."
ansible splunk_vm -m stat -a "path=/opt/splunk/bin/splunk" -b

# Check Splunk version
echo ""
echo "2. Checking Splunk version..."
ansible splunk_vm -m shell -a "/opt/splunk/bin/splunk version" -b

# Check if Splunk is running
echo ""
echo "3. Checking Splunk service status..."
ansible splunk_vm -m shell -a "/opt/splunk/bin/splunk status" -b

# Check Splunk processes
echo ""
echo "4. Checking Splunk processes..."
ansible splunk_vm -m shell -a "ps aux | grep splunk | grep -v grep" -b

# Check Splunk ports
echo ""
echo "5. Checking Splunk ports..."
ansible splunk_vm -m shell -a "ss -tlnp | grep -E ':(8000|8089|9997)'" -b

# Check firewall
echo ""
echo "6. Checking firewalld status..."
ansible splunk_vm -m shell -a "firewall-cmd --list-all" -b

# Check Splunk logs
echo ""
echo "7. Checking Splunk logs (last 30 lines)..."
ansible splunk_vm -m shell -a "tail -30 /opt/splunk/var/log/splunk/splunkd.log" -b

# Try to access web UI
echo ""
echo "8. Testing web UI access..."
ansible splunk_vm -m uri -a "url=http://172.20.242.20:8000 status_code=200,302 timeout=5" -b

echo ""
echo -e "${GREEN}Diagnostic complete. Check output above for issues.${NC}"
