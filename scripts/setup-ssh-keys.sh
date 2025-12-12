#!/usr/bin/env bash
# SSH Key Setup for CCDC Automation
# Sets up passwordless SSH from control node to all VMs

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   SSH Key Setup for CCDC                 ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# Configuration
KEY_NAME="ccdc_rsa"
KEY_PATH="$HOME/.ssh/$KEY_NAME"
VM_USER="sysadmin"

# VM Passwords
declare -A VM_PASSWORDS=(
    ["ubuntu_ecom_vm"]="changeme"
    ["fedora_webmail_vm"]="changeme"
    ["splunk_vm"]="changemenow"
)

# VM hosts (update these with your actual IPs)
declare -A VMS=(
    ["ubuntu_ecom_vm"]="172.20.242.104"
    ["fedora_webmail_vm"]="172.20.242.101"
    ["splunk_vm"]="172.20.242.20"
)

# Check sshpass is available
if ! command -v sshpass &>/dev/null; then
    echo -e "${RED}✗${NC} sshpass not found"
    echo "Installing sshpass..."

    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y sshpass
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm sshpass
    else
        echo -e "${RED}Cannot install sshpass automatically${NC}"
        echo "Please install manually: sudo apt-get install sshpass"
        exit 1
    fi

    echo -e "${GREEN}✓${NC} sshpass installed"
fi

# Step 1: Generate SSH key if doesn't exist
echo -e "${YELLOW}Step 1: Generating SSH key...${NC}"
if [[ -f "$KEY_PATH" ]]; then
    echo -e "${YELLOW}⚠${NC} Key already exists: $KEY_PATH"
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Using existing key"
    else
        rm -f "$KEY_PATH" "$KEY_PATH.pub"
        ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -C "ccdc-automation"
        echo -e "${GREEN}✓${NC} New key generated"
    fi
else
    ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -C "ccdc-automation"
    echo -e "${GREEN}✓${NC} SSH key generated: $KEY_PATH"
fi

# Step 2: Test password SSH to each VM
echo ""
echo -e "${YELLOW}Step 2: Testing password SSH to VMs...${NC}"
REACHABLE_VMS=()
UNREACHABLE_VMS=()

for vm_name in "${!VMS[@]}"; do
    vm_ip="${VMS[$vm_name]}"
    vm_pass="${VM_PASSWORDS[$vm_name]}"
    echo -n "  Testing $vm_name ($vm_ip)... "
    if sshpass -p "$vm_pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$VM_USER@$vm_ip" 'exit' 2>/dev/null; then
        echo -e "${GREEN}✓ Reachable${NC}"
        REACHABLE_VMS+=("$vm_name:$vm_ip")
    else
        echo -e "${RED}✗ Unreachable${NC}"
        UNREACHABLE_VMS+=("$vm_name:$vm_ip")
    fi
done

if [[ ${#REACHABLE_VMS[@]} -eq 0 ]]; then
    echo ""
    echo -e "${RED}✗ No VMs are reachable!${NC}"
    exit 1
fi

# Step 3: Copy SSH key to reachable VMs
echo ""
echo -e "${YELLOW}Step 3: Copying SSH key to VMs...${NC}"
for vm_entry in "${REACHABLE_VMS[@]}"; do
    vm_name="${vm_entry%%:*}"
    vm_ip="${vm_entry##*:}"
    vm_pass="${VM_PASSWORDS[$vm_name]}"
    echo -n "  Copying to $vm_name ($vm_ip)... "
    if sshpass -p "$vm_pass" ssh-copy-id -i "$KEY_PATH.pub" -o StrictHostKeyChecking=no "$VM_USER@$vm_ip" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Success${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
    fi
done

# Step 4: Test key-based SSH
echo ""
echo -e "${YELLOW}Step 4: Testing key-based SSH...${NC}"
SUCCESS_VMS=()
FAILED_VMS=()

for vm_entry in "${REACHABLE_VMS[@]}"; do
    vm_name="${vm_entry%%:*}"
    vm_ip="${vm_entry##*:}"

    echo -n "  Testing $vm_name ($vm_ip)... "

    if ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no "$VM_USER@$vm_ip" 'echo "Key auth works"' >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Key auth works${NC}"
        SUCCESS_VMS+=("$vm_name")
    else
        echo -e "${RED}✗ Key auth failed${NC}"
        FAILED_VMS+=("$vm_name")
    fi
done

# Step 5: Update ansible.cfg
echo ""
echo -e "${YELLOW}Step 5: Updating ansible.cfg...${NC}"

cp ansible.cfg ansible.cfg.backup.$(date +%s)

if grep -q "private_key_file" ansible.cfg; then
    sed -i "s|#*private_key_file.*|private_key_file = $KEY_PATH|" ansible.cfg
else
    sed -i "/

\[defaults\]

/a private_key_file = $KEY_PATH" ansible.cfg
fi

if ! grep -q "host_key_checking.*False" ansible.cfg; then
    sed -i "/

\[defaults\]

/a host_key_checking = False" ansible.cfg
fi

echo -e "${GREEN}✓${NC} ansible.cfg updated"

# Step 6: Update group_vars
echo ""
echo -e "${YELLOW}Step 6: Updating group_vars...${NC}"

if [[ -f "group_vars/linux_servers/connection.yml" ]]; then
    sed -i 's/^ansible_password:/#ansible_password:/' group_vars/linux_servers/connection.yml
    sed -i 's/^ansible_become_password:/#ansible_become_password:/' group_vars/linux_servers/connection.yml

    if ! grep -q "# Using SSH key authentication" group_vars/linux_servers/connection.yml; then
        cat >> group_vars/linux_servers/connection.yml <<'EOF'

# Using SSH key authentication (no password needed)
# SSH key: ~/.ssh/ccdc_rsa
# To re-enable password auth, uncomment lines above
EOF
    fi
fi   # <-- this was missing

# Step 7: Test with Ansible
echo ""
echo -e "${YELLOW}Step 7: Testing Ansible connectivity...${NC}"
if ansible all -m ping >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Ansible can connect to all hosts!"
    ansible all -m ping
else
    echo -e "${YELLOW}⚠${NC} Some hosts unreachable, running detailed test..."
    ansible all -m ping
fi

# Summary
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   SSH KEY SETUP COMPLETE                 ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""
echo "Results:"
echo "  Total VMs: ${#VMS[@]}"
echo "  Reachable: ${#REACHABLE_VMS[@]}"
echo "  Key auth working: ${#SUCCESS_VMS[@]}"
echo ""
