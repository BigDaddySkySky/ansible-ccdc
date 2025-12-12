#!/bin/bash

set -e

echo "=== Starting iterative cleanup ==="

MAX_PASSES=10
PASS=1

while [ $PASS -le $MAX_PASSES ]; do
    echo
    echo "=== Cleanup pass $PASS ==="

    # Track changes
    BEFORE=$(git status --porcelain | wc -l)

    echo "--- Running ansible-lint autofix ---"
    ansible-lint --write || true

    echo "--- Running pre-commit hooks ---"
    pre-commit run --all-files || true

    echo "--- Checking for remaining issues ---"
    AFTER=$(git status --porcelain | wc -l)

    if [ "$AFTER" -eq "$BEFORE" ]; then
        echo
        echo "✅ No further changes detected. Cleanup complete."
        exit 0
    fi

    PASS=$((PASS + 1))
done

echo
echo "⚠️ Reached maximum passes ($MAX_PASSES). Some issues may remain."
