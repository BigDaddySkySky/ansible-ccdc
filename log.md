# VyOS Logging Quick Reference Card

## Quick Setup (One Command Block)

```bash
configure
set system syslog global facility all level info
set system syslog host 172.20.242.20 facility all level info
set system syslog host 172.20.242.20 port 514
commit
save
exit
```

## Or Use the Script

```bash
sudo ./vyos_setup_logging.sh
```

## Test Logging

```bash
# Send test message
logger -t VYOS_TEST "Testing logging $(date)"

# Check it locally
show log | grep VYOS_TEST

# Check Splunk (search): host="vyos" VYOS_TEST
```

## View Logs

```bash
# Last 50 lines
show log tail 50

# Follow logs live
monitor log

# Firewall logs only
show log | grep firewall

# Authentication logs
show log | grep auth

# Specific time range
show log | match "Nov  1"
```

## Common Splunk Searches

### Find Your Router
```spl
host="172.16.101.1" OR host="vyos"
```

### Port Scan Detection
```spl
host="vyos" "DROP" | stats count by src | sort -count
```

### Failed SSH Attempts
```spl
host="vyos" "sshd" "Failed"
```

### Top Talkers
```spl
host="vyos" | stats count by src | sort -count | head 20
```

### Firewall Drops Last Hour
```spl
host="vyos" "DROP" earliest=-1h
```

### Suspicious Outbound
```spl
host="vyos" (dst_port=22 OR dst_port=23 OR dst_port=3389)
```

## During Competition

### When Red Team Detected

1. **Document in logs:**
   ```bash
   logger -t INCIDENT "Red Team detected from IP: X.X.X.X"
   ```

2. **Check what they hit:**
   ```bash
   show log | grep "X.X.X.X"
   ```

3. **Block them:**
   ```bash
   configure
   set firewall ipv4 name WAN-LAN rule 999 action drop
   set firewall ipv4 name WAN-LAN rule 999 source address X.X.X.X
   set firewall ipv4 name WAN-LAN rule 999 log
   commit
   save
   exit
   ```

4. **Search Splunk for their activity:**
   ```spl
   host="vyos" src="X.X.X.X"
   ```

5. **Export logs for incident report:**
   - Splunk → Export → CSV

### Monitoring Checklist

Every 5-10 minutes:

```bash
# Check for high volume of drops
show log tail 100 | grep DROP | wc -l

# Check recent unique sources
show log tail 100 | grep DROP | awk '{print $10}' | sort -u

# Look for authentication failures  
show log tail 50 | grep -i fail
```

## Incident Report Evidence

Include these from Splunk:

1. **First detection timestamp**
2. **Source IP(s)**
3. **Destination IPs/ports targeted**
4. **Number of attempts**
5. **Actions taken (firewall rules added)**
6. **Timeline of events**

## Useful VyOS Log Commands

```bash
# Configuration changes
show log | grep commit

# System errors
show log | grep -i error

# Kernel warnings
show log | grep kernel

# Last reboot
show log | grep reboot

# Interface changes
show log | grep interface
```

## Configure Different Log Levels

```bash
configure

# More verbose (debug)
set system syslog host 172.20.242.20 facility all level debug

# Less verbose (notice/warning)
set system syslog host 172.20.242.20 facility all level notice

# Errors only
set system syslog host 172.20.242.20 facility all level err

commit
save
exit
```

## Troubleshooting Logging

### Logs not in Splunk?

```bash
# 1. Can you reach Splunk?
ping 172.20.242.20

# 2. Is logging configured?
show system syslog

# 3. Are logs being generated?
show log tail 10

# 4. Test with logger
logger -t TEST "Hello Splunk"
show log | grep TEST
# Then check Splunk
```

### Too many logs?

```bash
configure
set system syslog host 172.20.242.20 facility all level warning
commit
save
exit
```

## Competition Timeline

**Min 0-5:** Run main hardening script
**Min 5-7:** Run logging script
**Min 7-8:** Verify logs in Splunk
**Min 8+:** Monitor and respond

## Critical: Set Up Before Red Team

Logs are your evidence!
- Can't prove Red Team activity without logs
- Can't write incident reports without logs
- Can't get incident response points without logs

**Set up logging in first 10 minutes!**

---

## Quick Copy-Paste Commands

**Setup:**
```bash
configure && set system syslog global facility all level info && set system syslog host 172.20.242.20 facility all level info && set system syslog host 172.20.242.20 port 514 && commit && save && exit
```

**Test:**
```bash
logger -t VYOS_TEST "Test $(date)" && show log | grep VYOS_TEST
```

**View:**
```bash
show log tail 50
```

**Block IP:**
```bash
configure && set firewall ipv4 name WAN-LAN rule 999 action drop && set firewall ipv4 name WAN-LAN rule 999 source address X.X.X.X && set firewall ipv4 name WAN-LAN rule 999 log && commit && save && exit
```

---

**Print this and keep it handy during competition!**
