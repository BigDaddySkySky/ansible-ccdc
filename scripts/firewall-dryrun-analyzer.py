#!/usr/bin/env python3
"""
Parse ansible-playbook --check output for the firewall role and summarize:
- rules that would be added
- ports that would be opened
- sysctl values that would change
- services that would be affected

Usage:
  ansible-playbook playbooks/30-hardening-main.yml --tags firewall --check | python scripts/firewall-dryrun-analyzer.py
  python scripts/firewall-dryrun-analyzer.py /path/to/check_output.txt
"""

import re
import sys
from collections import defaultdict


def read_input(path=None):
    if path:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            return f.read().splitlines()
    return sys.stdin.read().splitlines()


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else None
    lines = read_input(path)

    ports = set()
    services = set()
    rules = set()
    sysctls = set()

    port_patterns = [
        re.compile(r"port[:= ]+(\d+)/(tcp|udp)", re.IGNORECASE),
        re.compile(r"port[:= ]+(\d+)", re.IGNORECASE),
        re.compile(r"(\d+)/(tcp|udp)"),
    ]
    service_patterns = [
        re.compile(r'service name="([^"]+)"', re.IGNORECASE),
        re.compile(r"service[:= ]+([\w-]+)", re.IGNORECASE),
    ]
    sysctl_pattern = re.compile(r"net\.[a-z0-9_.]+", re.IGNORECASE)
    rule_pattern = re.compile(r"rich_rule|ufw|firewalld", re.IGNORECASE)

    for line in lines:
        # Ports
        for pat in port_patterns:
            m = pat.search(line)
            if m:
                if len(m.groups()) >= 2 and m.group(2):
                    ports.add(f"{m.group(1)}/{m.group(2).lower()}")
                else:
                    ports.add(m.group(1))
                break
        # Services
        for pat in service_patterns:
            m = pat.search(line)
            if m:
                services.add(m.group(1))
                break
        # Sysctl
        sm = sysctl_pattern.search(line)
        if sm:
            sysctls.add(sm.group(0))
        # Rules (summary)
        if rule_pattern.search(line):
            rules.add(line.strip())

    print("Firewall Dry-Run Analyzer")
    print("=========================")
    print(f"Ports to open ({len(ports)}): {', '.join(sorted(ports)) or 'None detected'}")
    print(f"Services affected ({len(services)}): {', '.join(sorted(services)) or 'None detected'}")
    print(f"Sysctl changes ({len(sysctls)}): {', '.join(sorted(sysctls)) or 'None detected'}")
    print("Rule-related lines:")
    if rules:
        for r in sorted(rules):
            print(f"  - {r}")
    else:
        print("  None detected")


if __name__ == "__main__":
    main()
