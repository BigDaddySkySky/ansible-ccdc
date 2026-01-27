# fim_aide

AIDE-based file integrity monitoring (baseline hashes + periodic checks).

- Injects monitored paths into the system AIDE config
- Initializes database on first run
- Runs `aide --check` via cron
- If differences are found, sends Discord alert using:
  `/usr/local/bin/ccdc-audit-alerts/send-discord-alert.py` (from the auditd role)
