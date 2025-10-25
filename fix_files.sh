#!/bin/bash
# fix_files.sh - Quick fixes for ansible repo

cd ~/ansible

echo "1. Fixing scoring_validation.yml typos..."
# Copy the fixed version from artifacts above

echo "2. Fixing mail_ports.yml typo..."
sed -i 's/mail_firewall__ports:/mail_firewall_ports:/' roles/firewall/vars/mail_ports.yml

echo "3. Creating group_vars reference files..."

# Create group_vars/linux.yml
cat > group_vars/linux.yml << 'EOF'
---
# Reference encrypted variables from vault.yml
ansible_ssh_pass: "{{ vault_linux_ssh_pass }}"
ansible_become_pass: "{{ vault_linux_become_pass }}"

# New passwords for reset playbook
linux_sysadmin_new: "{{ vault_linux_sysadmin_new }}"
linux_root_new: "{{ vault_linux_root_new }}"
EOF

# Create group_vars/windows.yml
cat > group_vars/windows.yml << 'EOF'
---
# Reference encrypted variables from vault.yml
ansible_password: "{{ vault_windows_admin_pass }}"

# New passwords for reset playbook
windows_admin_new: "{{ vault_windows_admin_new }}"
windows_userone_new: "{{ vault_windows_userone_new }}"
EOF

# Create group_vars/paloalto.yml
cat > group_vars/paloalto.yml << 'EOF'
---
ansible_user: admin
ansible_password: Changeme123
paloalto_pass_new: CompPalo2025!Secure
EOF

# Create group_vars/cisco_ftd.yml
cat > group_vars/cisco_ftd.yml << 'EOF'
---
ansible_user: admin
ansible_password: "!Changeme123"
cisco_ftd_pass_new: CompCisco2025!Secure
EOF

# Create group_vars/routers.yml
cat > group_vars/routers.yml << 'EOF'
---
ansible_user: vyos
ansible_password: changeme
vyos_pass_new: CompVyos2025!Secure
EOF

echo "4. Creating web_servers config files..."
cat > group_vars/web_servers/config.yml << 'EOF'
---
web_server_document_root: /var/www/html
web_server_max_clients: 150
EOF

cat > group_vars/web_servers/ports.yml << 'EOF'
---
# Web server specific port overrides (if needed)
# Uses global web_ports from all/ports.yml by default
EOF

echo "5. Fixing incident_response.yml regex..."
sed -i "s/grep -E 'nc|ncat|socat|reverse)'/grep -E 'nc|ncat|socat|reverse' | grep -v grep/" playbooks/incident_response.yml

echo "6. Fixing pre_check.yml vault path..."
sed -i 's|path: "{{ playbook_dir }}/../.vault_pass"|path: "~/.vault_pass"|' playbooks/pre_check.yml

echo ""
echo "✅ All fixes applied!"
echo ""
echo "Next steps:"
echo "1. Copy fixed scoring_validation.yml from artifacts"
echo "2. Copy fixed pass_reset.yml from artifacts"
echo "3. Verify: ansible-playbook playbooks/pre_check.yml"