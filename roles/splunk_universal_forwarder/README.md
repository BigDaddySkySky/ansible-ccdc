# splunk_universal_forwarder

Purpose:
- Install and configure the Splunk Universal Forwarder on endpoints

Used by:
- `install-forwarders` playbook

Changes:
- Installs Splunk Universal Forwarder package
- Configures forwarding to the Splunk server
- Enables and starts the forwarder service

Key Inputs (vars):
- splunk_forwarder_package_url
- splunk_receiver_host
- splunk_receiver_port

Notes:
- Assumes Splunk server is reachable
- Does not install Splunk server components
