#!/usr/bin/env bash
# V2.0 Bootstrap Script
# Supports: Arch Linux (local), Debian/Ubuntu (competition)

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== CCDC Ansible V2.0 Bootstrap ===${NC}"
echo ""

# Detect environment
if [[ -f /etc/arch-release ]]; then
    PKG_MANAGER="pacman"
    INSTALL_CMD="sudo pacman -S --noconfirm"
    echo -e "${GREEN}✓${NC} Detected: Arch Linux"
elif command -v apt-get &>/dev/null; then
    PKG_MANAGER="apt"
    INSTALL_CMD="sudo apt-get install -y"
    echo -e "${GREEN}✓${NC} Detected: Debian/Ubuntu"
elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="sudo dnf install -y"
    echo -e "${GREEN}✓${NC} Detected: Fedora/RHEL"
else
    echo -e "${RED}✗${NC} Unsupported distribution"
    exit 1
fi

# Check if we're in GitHub Codespaces
if [[ -n "${CODESPACES:-}" ]]; then
    echo -e "${YELLOW}⚠ Running in GitHub Codespaces${NC}"
    echo "Note: VM testing not available in Codespaces"
    CODESPACE=true
else
    CODESPACE=false
fi

# Install system dependencies
echo ""
echo -e "${YELLOW}Installing system dependencies...${NC}"

if [[ "$PKG_MANAGER" == "pacman" ]]; then
    # Arch-specific
    sudo pacman -Sy
    $INSTALL_CMD python python-pip python-virtualenv sshpass git
elif [[ "$PKG_MANAGER" == "apt" ]]; then
    # Debian/Ubuntu
    sudo apt-get update -qq
    $INSTALL_CMD python3 python3-pip python3-venv sshpass git
else
    # Fedora/RHEL
    $INSTALL_CMD python3 python3-pip sshpass git
fi

echo -e "${GREEN}✓${NC} System packages installed"

# Create virtual environment
echo ""
echo -e "${YELLOW}Setting up Python virtual environment...${NC}"

if [[ -d .venv ]]; then
    echo -e "${YELLOW}⚠ .venv already exists, removing...${NC}"
    rm -rf .venv
fi

python3 -m venv .venv
source .venv/bin/activate

echo -e "${GREEN}✓${NC} Virtual environment created"

# Install Python packages
echo ""
echo -e "${YELLOW}Installing Python packages...${NC}"

pip install --upgrade pip setuptools wheel
pip install ansible-core==2.16.0  # Latest stable

echo -e "${GREEN}✓${NC} Ansible installed"

# Install Ansible collections (minimal set for Sprint 0.5)
echo ""
echo -e "${YELLOW}Installing Ansible collections...${NC}"

ansible-galaxy collection install ansible.posix community.general

echo -e "${GREEN}✓${NC} Collections installed"

# Set up vault password
echo ""
echo -e "${YELLOW}Setting up vault password...${NC}"

VAULT_FILE="$HOME/.vault_pass"

if [[ -f "$VAULT_FILE" ]]; then
    echo -e "${GREEN}✓${NC} Vault password file already exists: $VAULT_FILE"
else
    echo "Enter vault password (or press Enter for default 'changeme'):"
    read -s VAULT_PASS
    VAULT_PASS=${VAULT_PASS:-changeme}
    
    echo "$VAULT_PASS" > "$VAULT_FILE"
    chmod 600 "$VAULT_FILE"
    
    echo -e "${GREEN}✓${NC} Vault password saved to: $VAULT_FILE"
fi

# Verify ansible.cfg points to vault file
if ! grep -q "vault_password_file.*\.vault_pass" ansible.cfg 2>/dev/null; then
    echo -e "${YELLOW}⚠ ansible.cfg not found or vault_password_file not set${NC}"
    echo "Creating minimal ansible.cfg..."
    
    cat > ansible.cfg << 'ANSIBLECFG'
[defaults]
inventory = inventory/staging.ini
vault_password_file = ~/.vault_pass
host_key_checking = False
timeout = 30
forks = 10
retry_files_enabled = False

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no
ANSIBLECFG
    
    echo -e "${GREEN}✓${NC} ansible.cfg created"
fi

# Verify installation
echo ""
echo -e "${YELLOW}Verifying installation...${NC}"

ansible --version | head -1
python3 --version

# Display next steps
echo ""
echo -e "${GREEN}=== Bootstrap Complete ===${NC}"
echo ""

if [[ "$CODESPACE" == true ]]; then
    echo -e "${YELLOW}Codespace Limitations:${NC}"
    echo "  - Cannot run VMs for testing"
    echo "  - Can edit playbooks and test syntax"
    echo "  - Push to GitHub, test on local machine"
    echo ""
fi

echo "Virtual environment activated! Next steps:"
echo ""
echo "  1. Test sprint deliverables:"
echo "     ./scripts/test-sprint.sh"
echo ""

if [[ "$CODESPACE" != true ]]; then
    echo "  2. Set up local VMs (BATTLE-STATION mode):"
    echo "     ./scripts/setup-vms.sh"
    echo ""
    echo "  3. Test hello-world:"
    echo "     ansible-playbook playbooks/00-hello-world.yml"
else
    echo "  2. Exit Codespace and test on local machine"
fi

echo ""
echo -e "${YELLOW}To activate venv in future sessions:${NC}"
echo "  source .venv/bin/activate"