#!/usr/bin/env bash
# ============================================================
# MWCCDC Ansible Bootstrap (Competition Mode)
#
# Purpose:
#   Prepare a known-good Ansible control environment for
#   competition execution. Strict and operator-friendly.
#
# Vault behavior:
#   - ~/.vault_pass is REQUIRED
#   - If missing, this script PROMPTS (hidden input) and creates it
#   - No hardcoded secrets
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

VERBOSE=0
for arg in "$@"; do
  case "$arg" in
    -v|--verbose) VERBOSE=1 ;;
  esac
done

log() { [[ $VERBOSE -eq 1 ]] && echo -e "$1"; }

die() {
  echo -e "${RED}✗${NC} $1" >&2
  exit 1
}

echo -e "${YELLOW}=== MWCCDC Ansible Bootstrap ===${NC}\n"

# ------------------------------------------------------------
# Environment detection
# ------------------------------------------------------------
if [[ -f /etc/arch-release ]]; then
  ENV="arch"
  echo -e "${GREEN}✓${NC} Environment: Arch Linux"
elif command -v apt-get &>/dev/null; then
  ENV="debian"
  echo -e "${GREEN}✓${NC} Environment: Debian/Ubuntu"
elif command -v dnf &>/dev/null; then
  ENV="fedora"
  echo -e "${GREEN}✓${NC} Environment: Fedora/RHEL"
else
  die "Unsupported distribution"
fi

# ------------------------------------------------------------
# System dependencies
# ------------------------------------------------------------
echo -e "\n${YELLOW}Installing system dependencies...${NC}"

case "$ENV" in
  arch)
    sudo pacman -Sy --noconfirm >/dev/null 2>&1 || true
    sudo pacman -S --noconfirm python python-pip python-virtualenv sshpass git >/dev/null 2>&1
    ;;
  debian)
    sudo apt-get update -qq >/dev/null 2>&1
    sudo apt-get install -y -qq python3 python3-pip python3-venv sshpass git >/dev/null 2>&1
    ;;
  fedora)
    sudo dnf install -y python3 python3-pip sshpass git >/dev/null 2>&1
    ;;
esac

echo -e "${GREEN}✓${NC} System packages ready"

# ------------------------------------------------------------
# Python virtual environment (mandatory)
# ------------------------------------------------------------
echo -e "\n${YELLOW}Preparing Python virtual environment...${NC}"

if [[ ! -d .venv ]]; then
  python3 -m venv .venv
fi

# shellcheck disable=SC1091
source .venv/bin/activate
echo -e "${GREEN}✓${NC} Virtual environment active"

# ------------------------------------------------------------
# Python dependencies
# ------------------------------------------------------------
echo -e "\n${YELLOW}Installing Ansible...${NC}"
pip install --upgrade pip setuptools wheel >/dev/null
pip install ansible-core==2.16.0 >/dev/null
echo -e "${GREEN}✓${NC} $(ansible --version | head -1)"

# ------------------------------------------------------------
# Ansible collections
# ------------------------------------------------------------
if [[ -f requirements.yml ]]; then
  echo -e "\n${YELLOW}Installing Ansible collections...${NC}"
  ansible-galaxy collection install -r requirements.yml --force
  echo -e "${GREEN}✓${NC} Collections installed"
fi

# ------------------------------------------------------------
# Vault setup (prompted, never hardcoded)
# ------------------------------------------------------------
echo ""
echo -e "${YELLOW}Validating vault configuration...${NC}"

VAULT_FILE="$HOME/.vault_pass"

if [[ ! -f "$VAULT_FILE" ]]; then
    echo -e "${RED}✗ Vault password file not found:${NC} $VAULT_FILE"
    echo ""
    echo "Create it manually before proceeding:"
    echo "  umask 077"
    echo "  nano ~/.vault_pass"
    echo ""
    echo "Bootstrap intentionally refuses to create secrets for you."
    exit 1
fi

chmod 600 "$VAULT_FILE"
echo -e "${GREEN}✓${NC} Vault password file present"

# ------------------------------------------------------------
# ansible.cfg (safe defaults, no forced inventory)
# ------------------------------------------------------------
if [[ ! -f ansible.cfg ]]; then
    echo ""
    echo -e "${YELLOW}Creating ansible.cfg...${NC}"

    cat > ansible.cfg << 'EOF'
[defaults]
vault_password_file = ~/.vault_pass
host_key_checking = False
timeout = 10
forks = 10
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 3600

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null

[privilege_escalation]
become = True
become_method = sudo
become_ask_pass = False
EOF

    echo -e "${GREEN}✓${NC} ansible.cfg created"
fi

# ------------------------------------------------------------
# SSH keypair (idempotent)
# ------------------------------------------------------------
echo ""
echo -e "${YELLOW}Ensuring SSH keypair exists...${NC}"

KEY_PATH="$HOME/.ssh/ccdc_rsa"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ ! -f "$KEY_PATH" ]]; then
    ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -C "ccdc@$(hostname)" >/dev/null
    chmod 600 "$KEY_PATH"
    chmod 644 "$KEY_PATH.pub"
    echo -e "${GREEN}✓${NC} SSH key generated"
else
    echo -e "${GREEN}✓${NC} SSH key already present"
fi

# ------------------------------------------------------------
# Optional: bootstrap SSH keys (memory guardrail)
# ------------------------------------------------------------
echo ""
read -r -p "Run SSH key bootstrap now? (recommended) [y/N]: " REPLY
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Running 00-bootstrap-keys.yml (will prompt for sudo password)...${NC}"
    ansible-playbook playbooks/00-bootstrap-keys.yml -k
fi

# ------------------------------------------------------------
# Final state
# ------------------------------------------------------------
echo ""
echo -e "${GREEN}=== Bootstrap Complete ===${NC}"
echo ""
echo "Environment: $ENV"
echo "Ansible: $(ansible --version | head -1)"
echo ""
echo "Next step (competition):"
echo "  ./scripts/preflight.sh"
echo "  ansible-playbook -i inventory/staging.ini playbooks/02-critical-path.yml"
echo ""
