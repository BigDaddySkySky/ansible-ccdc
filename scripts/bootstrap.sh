#!/usr/bin/env bash
# scripts/bootstrap.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== CCDC Ansible Bootstrap ===${NC}"
echo "Starting at: $(date)"
echo ""

check_ssh_password_auth() {
  echo -e "${YELLOW}Checking SSH password authentication...${NC}"
  if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config 2>/dev/null; then
    echo -e "${GREEN}✓ SSH password auth enabled${NC}"
  elif grep -q "^#PasswordAuthentication" /etc/ssh/sshd_config 2>/dev/null; then
    echo -e "${YELLOW}⚠ SSH password auth commented (usually defaults to yes)${NC}"
  else
    echo -e "${RED}✗ SSH password auth may be disabled${NC}"
    echo "To enable: sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config"
    echo "Then run: sudo systemctl restart sshd"
  fi
  echo ""
}

install_packages() {
  echo -e "${YELLOW}Installing required packages...${NC}"

  if command -v apt-get &> /dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y python3 python3-pip python3-apt sshpass
    echo -e "${GREEN}✓ Packages installed (Debian/Ubuntu)${NC}"
  elif command -v dnf &> /dev/null; then
    sudo dnf install -y python3 python3-pip sshpass
    echo -e "${GREEN}✓ Packages installed (RHEL/Fedora)${NC}"
  else
    echo -e "${RED}✗ Unsupported package manager${NC}"
    exit 1
  fi
  echo ""
}

upgrade_ansible() {
  echo -e "${YELLOW}Upgrading Ansible to core 2.15+...${NC}"

  CURRENT_VERSION=$(ansible --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+' || echo "0.0.0")
  echo "Current version: $CURRENT_VERSION"

  pip3 install --user --upgrade ansible-core

  NEW_VERSION=$(~/.local/bin/ansible --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+' || ansible --version | head -1 | grep -oP '\d+\.\d+\.\d+')
  echo "New version: $NEW_VERSION"

  if [[ ! "$PATH" =~ /.local/bin ]]; then
    echo -e "${YELLOW}⚠ Adding ~/.local/bin to PATH${NC}"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    export PATH="$HOME/.local/bin:$PATH"
  fi

  echo -e "${GREEN}✓ Ansible upgraded${NC}"
  echo ""
}

verify_installation() {
  echo -e "${YELLOW}Verifying installation...${NC}"

  for cmd in python3 pip3 ansible sshpass; do
    if command -v $cmd &> /dev/null; then
      VERSION=$($cmd --version 2>&1 | head -1 || echo "unknown")
      echo -e "${GREEN}✓${NC} $cmd: $VERSION"
    else
      echo -e "${RED}✗${NC} $cmd: NOT FOUND"
    fi
  done
  echo ""
}

check_vault_pass() {
  echo -e "${YELLOW}Checking vault password file...${NC}"

  if [[ -f ~/.vault_pass ]]; then
    echo -e "${GREEN}✓ ~/.vault_pass exists${NC}"
  elif [[ -f .vault_pass ]]; then
    echo -e "${GREEN}✓ .vault_pass exists (local)${NC}"
  else
    echo -e "${YELLOW}⚠ No vault password file found${NC}"
    echo "Create one with: echo 'your_password' > ~/.vault_pass && chmod 600 ~/.vault_pass"
  fi
  echo ""
}

main() {
  check_ssh_password_auth
  install_packages
  upgrade_ansible
  verify_installation
  check_vault_pass

  echo -e "${GREEN}=== Bootstrap Complete ===${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Ensure .vault_pass or ~/.vault_pass is configured"
  echo "  2. Test connectivity: ansible all -m ping"
  echo "  3. Run playbooks: ansible-playbook playbooks/run_all.yml"
  echo ""
}

main