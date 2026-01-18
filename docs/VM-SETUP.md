# VM Setup Guide (VMware Workstation Pro)

## Overview

Validate your V2.0 automation against VMware VMs that mirror the competition environment.

## Why VMs?

1. **Repeatability:** Snapshot in your practice environment before validation, rollback if broken
2. **Safety:** Break VMs all you want, not your actual system
3. **Reality Check:** Competition runs on real VMs, not localhost

## Minimum VMs for Practice

**Sprint 0.5 - 1:**
- 1 Ubuntu 22.04 VM (ubuntu-ecom-vm)

**Sprint 2 - 3:**
- 1 Ubuntu 22.04 VM (ubuntu-ecom-vm)
- 1 Fedora 39 VM (fedora-webmail-vm)

**Sprint 4+:**
- Add 3rd VM for role isolation validation

## Step-by-Step: Create Ubuntu VM

### 1. Download Ubuntu Server

- URL: https://ubuntu.com/download/server
- Version: **22.04 LTS** (what competition likely uses)
- File: `ubuntu-22.04.x-live-server-amd64.iso`

### 2. Create VM in VMware Workstation

**GUI Method (Easier):**

1. Open VMware Workstation Pro
2. File → New Virtual Machine → Typical
3. Installer disc image: Browse to Ubuntu ISO
4. **Settings:**
   - Name: `ccdc-ubuntu-ecom`
   - Location: Wherever you want
   - Disk: 20 GB, single file (faster)
   - Customize Hardware:
     - Memory: 2048 MB (2 GB)
     - Processors: 2 cores
     - Network: NAT (default) ✓ Connect at power on
5. Finish → Power on

### 3. Ubuntu Installation

**Important Settings During Install:**
```
Profile Setup:
  Your name: CCDC User
  Server name: ubuntu-ecom-vm
  Username: ccdc
  Password: changeme

SSH Setup:
  [X] Install OpenSSH server  ← CRITICAL!

Featured Server Snaps:
  [ ] Don't select any (we'll install via Ansible)
```

**Wait for installation to complete** (5-10 minutes)

### 4. Post-Install Configuration

After VM reboots, login with `ccdc` / `changeme`:
```bash
# Check IP address
ip addr show

# You'll see something like:
# inet 192.168.xxx.xxx/24

# Write down this IP! You'll need it for inventory.

# Validate SSH from your host machine
# From your Windows/Linux host terminal:
ssh ccdc@192.168.xxx.xxx
# Password: changeme

# If SSH works, you're good!
```

### 5. Update inventory/staging.ini
```bash
# Edit inventory/staging.ini
# Replace IP with your VM's actual IP:

[linux_servers]
ubuntu_ecom_vm ansible_host=192.168.xxx.xxx  # ← YOUR VM'S IP
```

### 6. Create VM Snapshot (CRITICAL!)

**Before running ANY playbooks in your practice environment:**

1. VMware → VM → Snapshot → Take Snapshot
2. Name: `Sprint 0.5 - Fresh Install`
3. Description: `Clean Ubuntu 22.04 install, SSH working`

**Why?** If automation breaks the VM, you can rollback in 10 seconds instead of reinstalling for 20 minutes.

## VMware Cheat Sheet

### Common Tasks
```bash
# Take snapshot (before validation in your practice environment)
# GUI: VM → Snapshot → Take Snapshot

# Revert to snapshot (if you broke something in practice)
# GUI: VM → Snapshot → Revert to Snapshot

# Clone VM (to create 2nd/3rd VMs)
# GUI: Right-click VM → Manage → Clone
# Choose: "Create a linked clone" (saves disk space)
```

### Networking Modes

**NAT (Default):** ✅ Recommended
- VMs can reach internet
- Host can reach VMs
- VMs can reach each other
- IPs are assigned by VMware DHCP (usually 192.168.xxx.xxx)

**Bridged:** ❌ Avoid unless needed
- VMs get IPs from your home router
- More "realistic" but harder to manage

**Host-Only:** ❌ Avoid
- VMs isolated from internet
- Breaks package installs

## Troubleshooting

### Can't SSH to VM
```bash
# From VM console (login directly):
sudo systemctl status sshd

# If not running:
sudo systemctl start sshd
sudo systemctl enable sshd

# Check firewall:
sudo ufw status
# If active, allow SSH:
sudo ufw allow 22/tcp
```

### VM Too Slow

Your BATTLE-STATION can handle it, but if VMs lag:
1. Increase RAM: VM → Settings → Memory → 3 GB
2. Increase cores: VM → Settings → Processors → 2 cores
3. Close other VMs

### Forgot VM IP
```bash
# From VM console:
ip addr show | grep inet

# Or from host (if VM is running):
# VMware manages DHCP, check:
# Windows: C:\ProgramData\VMware\vmnetdhcp.conf
# Linux: /etc/vmware/vmnet8/dhcpd/dhcpd.leases
```

## Next Steps

Once you have 1 VM working:
1. Test hello-world: `ansible-playbook playbooks/00-hello-world.yml`
2. Create 2nd VM (clone the first one!)
3. Start Sprint 1

## Advanced: CLI VM Creation (Optional)

VMware has `vmrun` CLI tool, but GUI is easier for now.

For automation enthusiasts, see: `scripts/create-vms-vmware.sh` (Coming in Sprint 1)
