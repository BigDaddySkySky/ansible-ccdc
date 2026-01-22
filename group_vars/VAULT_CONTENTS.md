# Vaulted Variables – group_vars

This directory contains encrypted Ansible Vault files for the purpose of obfuscating credentials.
This document describes *what categories of data live here*, not their values.

## Stored Here
- Discord / alerting webhooks
- Shared admin passwords used for initial password rotation

## Declared Variables
- vault_discord_webhook_url
- vault_default_password

## Notes
- No IP addresses or hostnames are changed by these values
- Values are intentionally obfuscated via ansible-vault to protect credentials
