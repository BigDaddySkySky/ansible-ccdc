#!/usr/bin/env python3
"""
Simple repo-wide YAML syntax fixer.
- Removes trailing spaces
- Ensures newline at EOF
- Normalizes common YAML truthy values: yes/no/on/off/true/false -> true/false (unquoted)

Run from repo root. It only edits .yml/.yaml files under playbooks, roles, group_vars, host_vars, and the top-level playbooks/roles.
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGET_DIRS = ["playbooks", "roles", "group_vars", "host_vars", "web_servers", "network_devices", "windows", "scripts"]
YAML_EXTS = {".yml", ".yaml"}

# Pattern to replace lines like: key: yes  OR key: "yes"  OR - yes  (we'll avoid changing quoted values)
TRUTHY_PATTERN = re.compile(r'^(?P<prefix>\s*[^#:][^:]*:\s*)(?P<val>yes|no|Yes|No|YES|NO|on|off|On|Off|true|false|True|False)\s*$')

# Also handle simple list items: - yes
LIST_TRUTHY_PATTERN = re.compile(r'^(?P<prefix>\s*-\s*)(?P<val>yes|no|Yes|No|YES|NO|on|off|On|Off|true|false|True|False)\s*$')

changed_files = []

for d in TARGET_DIRS:
    path = ROOT / d
    if not path.exists():
        continue
    for p in path.rglob("*"):
        if p.is_file() and p.suffix in YAML_EXTS:
            try:
                text = p.read_text(encoding="utf-8")
            except Exception:
                continue
            orig = text
            # Normalize newlines
            text = text.replace('\r\n', '\n')
            lines = text.split('\n')
            new_lines = []
            for line in lines:
                # Remove trailing spaces
                line2 = re.sub(r"[ \t]+$", "", line)
                # Normalize truthy for key: value patterns (only if not quoted)
                m = TRUTHY_PATTERN.match(line2)
                if m:
                    val = m.group('val')
                    val_low = val.lower()
                    if val_low in ('yes', 'on', 'true'):
                        line2 = f"{m.group('prefix')}true"
                    else:
                        line2 = f"{m.group('prefix')}false"
                else:
                    m2 = LIST_TRUTHY_PATTERN.match(line2)
                    if m2:
                        val = m2.group('val')
                        val_low = val.lower()
                        if val_low in ('yes', 'on', 'true'):
                            line2 = f"{m2.group('prefix')}true"
                        else:
                            line2 = f"{m2.group('prefix')}false"
                new_lines.append(line2)
            # Ensure single newline at EOF
            new_text = '\n'.join(new_lines).rstrip('\n') + '\n'
            if new_text != orig:
                p.write_text(new_text, encoding="utf-8")
                changed_files.append(str(p.relative_to(ROOT)))

# Print summary
if changed_files:
    print("Fixed files:")
    for f in changed_files:
        print(f)
else:
    print("No changes made")

print(f"Total files changed: {len(changed_files)}")
