# What failed at the invitational

cat > INVITATIONAL_POSTMORTEM.md << 'EOF'
# What failed at the invitational


## Critical
- Setup was messy
  - Script new bootstrap for python setup
- Communicate with team importance of SSH access from ansible control node
  - Further: Ensure any firewall rules allow this
  - `sshd` should be ready on targets
- Playbooks failed: cited unreachable

## V2.0 Must Haves
### First 5-Minutes
- Bootstrap script that should set up ansible environment.
```pseudo
# sshpass for initial auth, python3 packages to set up a venv, git for repo pull
Install sshpass python3 python3-pip python3-venv git 

clone repo
cd into repo

python3 -m venv .venv
source .venv/bin/activate

pip install requirements.txt
ansible install requirements.yml
```
- Playbook to check envrionment, i.e. what hosts are initially visible?
  - Determine who to prioritize connection for playbooks
### First 20-minutes
- Playbooks have ran.
- Any packages installed via ansible have done so
- Discord notifications working
