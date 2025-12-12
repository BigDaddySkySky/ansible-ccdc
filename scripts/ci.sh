#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

python -m pip install --upgrade pip
pip install ansible ansible-lint yamllint
ansible-galaxy collection install -r requirements.yml

echo "[CI] ansible-lint"
ansible-lint

echo "[CI] yamllint"
yamllint .

echo "[CI] playbook syntax-check"
for pb in playbooks/*.yml; do
  ansible-playbook --syntax-check "$pb"
done

echo "[CI] inventory validation"
ansible-inventory -i inventory/staging.ini --list >/dev/null
ansible-inventory -i inventory/production.ini --list >/dev/null

echo "[CI] done"
