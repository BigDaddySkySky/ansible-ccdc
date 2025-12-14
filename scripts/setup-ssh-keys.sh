#!/usr/bin/env bash
# Inventory-driven SSH key setup (range-safe)
# - Reads hosts from an Ansible inventory
# - Uses host_vars/<host>/vault.yml (ansible-vault) for password
# - Copies a key to each reachable host using ssh-copy-id
# - DOES NOT edit ansible.cfg or group_vars

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

INVENTORY="${1:-inventory/range.ini}"
KEY_NAME="${2:-ccdc_rsa}"
KEY_PATH="$HOME/.ssh/$KEY_NAME"

# Which inventory groups to target (edit if you want)
TARGET_GROUPS=("linux_servers" "security_tools" "unix_servers" "attack_tools")

# Dependencies
need() { command -v "$1" >/dev/null 2>&1 || { echo -e "${RED}Missing dependency:${NC} $1"; exit 1; }; }

need ansible
need ansible-inventory
need ssh
need ssh-copy-id
need ssh-keygen

if ! command -v sshpass >/dev/null 2>&1; then
  echo -e "${YELLOW}sshpass not found.${NC} Installing..."
  if command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y sshpass
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get install -y sshpass
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y sshpass
  else
    echo -e "${RED}Cannot auto-install sshpass. Install it manually.${NC}"
    exit 1
  fi
fi

echo -e "${BLUE}Using inventory:${NC} $INVENTORY"
echo -e "${BLUE}Using key:${NC} $KEY_PATH"

# 1) Generate key if missing
if [[ -f "$KEY_PATH" ]]; then
  echo -e "${GREEN}✓${NC} Key exists: $KEY_PATH"
else
  echo -e "${YELLOW}Generating SSH key...${NC}"
  ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -C "ccdc-range-automation"
  echo -e "${GREEN}✓${NC} Key generated"
fi

# 2) Ask for vault password once (so we can read vaulted vars)
# (If your ansible.cfg has vault_password_file, this won't prompt.)
echo -e "${YELLOW}Loading inventory (this may prompt for vault password)...${NC}"

# 3) Build host list from groups
HOSTS=()
for grp in "${TARGET_GROUPS[@]}"; do
  # This prints hosts in that group; ignore errors if group doesn't exist
  while IFS= read -r h; do
    [[ -n "$h" ]] && HOSTS+=("$h")
  done < <(ansible-inventory -i "$INVENTORY" --graph "$grp" 2>/dev/null | awk '/^\s+\|--/ {print $2}' || true)
done

# Deduplicate
mapfile -t HOSTS < <(printf "%s\n" "${HOSTS[@]}" | awk '!seen[$0]++')

if [[ ${#HOSTS[@]} -eq 0 ]]; then
  echo -e "${RED}No hosts found from target groups in inventory.${NC}"
  echo "Groups tried: ${TARGET_GROUPS[*]}"
  exit 1
fi

echo -e "${BLUE}Targets:${NC} ${HOSTS[*]}"

# Helper: get a host var via ansible-inventory host dump
get_host_var() {
  local host="$1"
  local var="$2"
  ansible-inventory -i "$INVENTORY" --host "$host" \
    | python3 - <<'PY' "$var"
import json,sys
var=sys.argv[1]
data=json.load(sys.stdin)
print(data.get(var,""))
PY
}

REACHABLE=()
FAILED=()

# 4) Copy key to each host
for host in "${HOSTS[@]}"; do
  ip="$(get_host_var "$host" "ansible_host")"
  user="$(get_host_var "$host" "ansible_user")"
  pass="$(get_host_var "$host" "vault_default_password")"

  if [[ -z "$ip" || -z "$user" ]]; then
    echo -e "${YELLOW}Skipping ${host}:${NC} missing ansible_host or ansible_user"
    continue
  fi

  # Some hosts may not have a password var (e.g., if not vaulted yet)
  if [[ -z "$pass" ]]; then
    echo -e "${YELLOW}Skipping ${host}:${NC} missing vault_default_password (host_vars not set?)"
    continue
  fi

  echo -n "Copying key to ${host} (${user}@${ip})... "

  # Quick connectivity test with password auth
  if ! sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
      -o PreferredAuthentications=password -o PubkeyAuthentication=no \
      "${user}@${ip}" "echo ok" >/dev/null 2>&1; then
    echo -e "${RED}✗ unreachable${NC}"
    FAILED+=("$host")
    continue
  fi

  # Copy key
  if sshpass -p "$pass" ssh-copy-id -i "${KEY_PATH}.pub" -o StrictHostKeyChecking=no "${user}@${ip}" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    REACHABLE+=("$host")
  else
    echo -e "${RED}✗ copy failed${NC}"
    FAILED+=("$host")
  fi
done

echo
echo -e "${BLUE}Key copy complete.${NC}"
echo "  Success: ${#REACHABLE[@]}  Failed: ${#FAILED[@]}"

# 5) Verify key auth
echo
echo -e "${YELLOW}Verifying key-based SSH...${NC}"
BADKEY=()
for host in "${REACHABLE[@]}"; do
  ip="$(get_host_var "$host" "ansible_host")"
  user="$(get_host_var "$host" "ansible_user")"

  echo -n "Testing ${host}... "
  if ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
      "${user}@${ip}" "echo key_ok" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
  else
    echo -e "${RED}✗${NC}"
    BADKEY+=("$host")
  fi
done

echo
if [[ ${#BADKEY[@]} -gt 0 ]]; then
  echo -e "${YELLOW}Some hosts did not accept key auth:${NC} ${BADKEY[*]}"
  echo "Common causes: root SSH disabled, password auth disabled, sshd config, or wrong user."
else
  echo -e "${GREEN}All tested hosts accept key auth.${NC}"
fi

echo
echo -e "${BLUE}Next step:${NC} set this in ansible.cfg (range branch) if you want:"
echo "  private_key_file = $KEY_PATH"
