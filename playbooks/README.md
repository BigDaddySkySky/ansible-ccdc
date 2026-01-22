# Playbooks

This directory contains the **competition execution path**.
Playbooks are numbered in the required run order.

Only playbooks listed below have been validated end-to-end.

---

## Run Order (Competition)

1. `00-bootstrap-keys.yml`  
   Establish reliable SSH access.

2. `01-rotate-passwords.yml`  
   Rotate credentials after access is confirmed.

3. `02-critical-path.yml`  
   Apply baseline competition hardening.

4. `03-configure-splunk.yml`  
   Configure Splunk server and management settings.

5. `04-install-forwarders.yml`  
   Deploy Splunk Universal Forwarders to endpoints.
