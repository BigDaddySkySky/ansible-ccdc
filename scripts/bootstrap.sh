#!/usr/bin/env bash
# V2.0 Bootstrap Script (Quiet Mode with Optional Verbose Flag)
# Supports: Arch Linux, Debian/Ubuntu, Fedora, GitHub Codespaces
# Usage: ./bootstrap.sh [-v|--verbose]

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Parse arguments for verbose mode
VERBOSE=0
for arg in "$@"; do
    if [[ "$arg" == "-v" ]] || [[ "$arg" == "--verbose" ]]; then
        VERBOSE=1
        echo -e "${YELLOW}Running in VERBOSE mode${NC}"
        echo ""
    fi
done

echo -e "${YELLOW}=== CCDC Ansible V2.0 Bootstrap ===${NC}"
echo ""

# Detect environment
if [[ -n "${CODESPACES:-}" ]]; then
    ENV="codespaces"
    echo -e "${GREEN}✓${NC} Detected: GitHub Codespaces"
    echo -e "${YELLOW}⚠ Note: Cannot run VMs in Codespaces (test on local machine)${NC}"
elif [[ -f /etc/arch-release ]]; then
    ENV="arch"
    echo -e "${GREEN}✓${NC} Detected: Arch Linux"
elif command -v apt-get &>/dev/null; then
    ENV="debian"
    echo -e "${GREEN}✓${NC} Detected: Debian/Ubuntu"
elif command -v dnf &>/dev/null; then
    ENV="fedora"
    echo -e "${GREEN}✓${NC} Detected: Fedora/RHEL"
else
    echo -e "${RED}✗${NC} Unsupported distribution"
    exit 1
fi

# Install system dependencies
echo ""
echo -e "${YELLOW}Installing system dependencies...${NC}"

case "$ENV" in
    arch)
        if [[ $VERBOSE -eq 1 ]]; then
            sudo pacman -Sy --noconfirm
            sudo pacman -S --noconfirm python python-pip python-virtualenv sshpass git ansible-core
        else
            sudo pacman -Sy --noconfirm > /dev/null 2>&1
            sudo pacman -S --noconfirm python python-pip python-virtualenv sshpass git > /dev/null 2>&1
        fi
        ;;
    debian|codespaces)
        if [[ $VERBOSE -eq 1 ]]; then
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip python3-venv sshpass git ansible-core
        else
            sudo apt-get update -qq > /dev/null 2>&1
            sudo apt-get install -y -qq python3 python3-pip python3-venv sshpass git > /dev/null 2>&1
        fi
        ;;
    fedora)
        if [[ $VERBOSE -eq 1 ]]; then
            sudo dnf install -y python3 python3-pip sshpass git ansible-core
        else
            sudo dnf install -y -q python3 python3-pip sshpass git > /dev/null 2>&1
        fi
        ;;
esac

echo -e "${GREEN}✓${NC} System packages installed"

# Create virtual environment
echo ""
echo -e "${YELLOW}Setting up Python virtual environment...${NC}"

if [[ -d .venv ]]; then
    echo -e "${YELLOW}⚠ .venv already exists${NC}"
    read -p "Recreate? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf .venv
    else
        echo "Using existing .venv"
    fi
fi

if [[ ! -d .venv ]]; then
    python3 -m venv .venv
fi

source .venv/bin/activate

echo -e "${GREEN}✓${NC} Virtual environment ready"

# Install Python packages
echo ""
echo -e "${YELLOW}Installing Python packages...${NC}"

if [[ $VERBOSE -eq 1 ]]; then
    pip install --upgrade pip setuptools wheel
    pip install ansible-core==2.16.0
else
    pip install --quiet --upgrade pip setuptools wheel 2>&1 | grep -iE "(error|failed)" || true
    pip install --quiet ansible-core==2.16.0 2>&1 | grep -iE "(error|failed)" || true
fi

echo -e "${GREEN}✓${NC} Ansible installed ($(ansible --version | head -1))"

# Install Ansible collections
echo ""
echo -e "${YELLOW}Installing Ansible collections...${NC}"

if [[ $VERBOSE -eq 1 ]]; then
    ansible-galaxy collection install ansible.posix community.general
else
    ansible-galaxy collection install ansible.posix community.general > /dev/null 2>&1
fi

echo -e "${GREEN}✓${NC} Collections installed"

# Set up vault password
echo ""
echo -e "${YELLOW}Setting up vault password...${NC}"

VAULT_FILE="$HOME/.vault_pass"

if [[ -f "$VAULT_FILE" ]]; then
    echo -e "${GREEN}✓${NC} Vault password file exists: $VAULT_FILE"
else
    echo "Enter vault password (or press Enter for default 'changeme'):"
    read -s VAULT_PASS
    VAULT_PASS=${VAULT_PASS:-changeme}
    
    echo "$VAULT_PASS" > "$VAULT_FILE"
    chmod 600 "$VAULT_FILE"
    
    echo -e "${GREEN}✓${NC} Vault password saved to: $VAULT_FILE"
fi

# Create/verify ansible.cfg
echo ""
echo -e "${YELLOW}Configuring Ansible...${NC}"

if [[ ! -f ansible.cfg ]]; then
    cat > ansible.cfg << 'ANSIBLECFG'
[defaults]
inventory = inventory/staging.ini
vault_password_file = ~/.vault_pass
host_key_checking = False
timeout = 10
remote_user = ccdc
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
ANSIBLECFG
    
    echo -e "${GREEN}✓${NC} ansible.cfg created"
else
    echo -e "${GREEN}✓${NC} ansible.cfg already exists"
fi

# Display summary
echo ""
echo -e "${GREEN}=== Bootstrap Complete ===${NC}"
echo ""
echo "Environment: $ENV"
echo "Ansible: $(ansible --version | head -1)"
echo "Python: $(python3 --version)"
echo ""

if [[ "$ENV" == "codespaces" ]]; then
    echo -e "${YELLOW}Codespaces Limitations:${NC}"
    echo "  - Cannot run VMs here"
    echo "  - Use for editing playbooks only"
    echo "  - Test on local machine (Arch/Windows)"
    echo ""
fi

echo "Virtual environment activated! Next steps:"
echo ""
echo "  1. Test sprint deliverables:"
echo "     ./scripts/test-sprint.sh"
echo ""

if [[ "$ENV" != "codespaces" ]]; then
    echo "  2. Create VMware VMs (see docs/VM-SETUP.md)"
    echo ""
    echo "  3. Test hello-world:"
    echo "     ansible-playbook playbooks/00-hello-world.yml"
else
    echo "  2. Exit Codespaces and test on local machine"
fi

echo ""
echo -e "${YELLOW}To activate venv in future sessions:${NC}"
echo "  source .venv/bin/activate"
echo ""

if [[ $VERBOSE -eq 0 ]]; then
    echo -e "${YELLOW}Tip: Run with -v or --verbose flag to see detailed output${NC}"
fi
