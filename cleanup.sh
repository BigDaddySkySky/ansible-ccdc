# Encrypt all vault.yml files
find group_vars -name "vault.yml" -exec ansible-vault encrypt {} \
  --vault-password-file ~/.vault_pass \
  --encrypt-vault-id default \;

# Encrypt Splunk host_vars
ansible-vault encrypt host_vars/splunk.yml \
  --vault-password-file ~/.vault_pass \
  --encrypt-vault-id default

# Verify encryption
head -1 group_vars/linux/vault.yml
