# VM Setup Guide for Testing

## Overview

Test your V2.0 automation against VMs that mirror the competition environment. This prevents "works on my machine" issues during competition.

## Minimum VM Requirements

For Sprint 0.5 testing:
- 1 Linux VM (Ubuntu 22.04 or Fedora 38+)
- SSH access
- Python 3.8+
- sudo privileges

For Sprint 1+ testing:
- 2-3 Linux VMs
- 1 Windows VM (optional)
- Bridge or NAT networking

## Quick Setup (Using Vagrant)
```bash
# Coming in Sprint 1
```

## Quick Setup (Manual VMs)

1. **Create Ubuntu VM**
   - Allocate 2GB RAM, 20GB disk
   - Install Ubuntu Server 22.04
   - Set hostname: `ubuntu-ecom-vm`
   - Create user: `ccdc` / `changeme`
   - Install SSH: `sudo apt install openssh-server`
   - Enable SSH: `sudo systemctl enable --now ssh`

2. **Update staging inventory**
```bash
   # Edit inventory/staging.ini
   ubuntu_ecom_vm ansible_host=<VM_IP>
```

3. **Test connectivity**
```bash
   ansible -i inventory/staging.ini all -m ping
```

## IP Addressing

Your VMs should use a private subnet that doesn't conflict with competition IPs:
- Competition uses: 172.20.x.x, 172.16.x.x
- Suggested for VMs: 192.168.122.x (libvirt default)

## Snapshot Before Testing

Always snapshot your VMs before running playbooks:
```bash
# KVM/libvirt example
virsh snapshot-create-as ubuntu-ecom-vm sprint0.5-baseline
```

This lets you roll back if automation breaks something.