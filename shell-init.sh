# Initialize fleetctl
SSH_CONFIG=$(vagrant ssh-config)
SSH_HOST=$(awk '{ if($1=="HostName") print $2}' <<< "$SSH_CONFIG" | head -1)
SSH_PORT=$(awk '{ if($1=="Port") print $2}' <<< "$SSH_CONFIG" | head -1)
SSH_KEY_FILE=$(awk '{ if($1=="IdentityFile") print $2}' <<< "$SSH_CONFIG" | head -1)

rm ~/.fleetctl/known_hosts
ssh-add $SSH_KEY_FILE
export FLEETCTL_TUNNEL=$SSH_HOST:$SSH_PORT