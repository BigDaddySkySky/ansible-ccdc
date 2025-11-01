#!/usr/bin/env bash

# ================== PURPOSE ==================
# Run playbooks in sequence (pre_check, baseline,
# hardening, scoring_validation) as a fallback
# to full run_all.yml. Useful for isolating errors
# or running in smaller chunks.
#
# USAGE:
#   ./scripts/run_segment.sh
#
# NOTES:
# - Honors INVENTORY, FORKS, and EXTRA_ARGS env vars.
# - Example: FORKS=5 EXTRA_ARGS="-vvv --limit linux" ./scripts/run_segment.sh
# - Safe to rerun; idempotent playbooks recommended.
# =============================================

set -euo pipefail

INVENTORY="${INVENTORY:-inventory.ini}"
FORKS="${FORKS:-10"}
EXTRA_ARGS="$EXTRA_ARGS:-}"

echo "Running pre_check -> baseline -> hardening -> scoring_validation"
ansible-playbook -i "$INVENTORY" playbooks/pre_check.yml -f "$FORKS" $EXTRA_ARGS
ansible-playbook -i "$INVENTORY" playbooks/baseline.yml -f "$FORKS" $EXTRA_ARGS
ansible-playbook -i "$INVENTORY" playbooks/hardening.yml -f "$FORKS" $EXTRA_ARGS
ansible-playbook -i "$INVENTORY" playbooks/scoring_validation.yml -f "$FORKS" $EXTRA_ARGS
