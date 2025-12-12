# Role: common_notify

Purpose
- Send standardized Discord notifications after critical playbooks.

When to Run
- Called by playbooks needing broadcast (e.g., `30-hardening-main.yml`).

Variables Required
- `discord_webhook_url` (usually `vault_discord_webhook_url`), optional `discord_title`, `discord_description`, `discord_color`.

Dependencies
- Internet egress to Discord; `uri` module; webhook present in vault.

Run Steps
- Included via `include_role`; set vars above. Example:
  - vars:
      discord_title: "Hardening Complete"
      discord_description: "SSH/Firewall/Auditd applied"
      discord_webhook_url: "{{ vault_discord_webhook_url }}"

Validation
- Task returns 200/204; confirm message in Discord channel.

White Team Visibility
- Outbound webhook only; content summarizes actions for transparency; no host changes.

Inject Impact
- Automated comms free a teammate from manual updates during inject handling.
