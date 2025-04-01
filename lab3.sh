#!/bin/bash

# Enable verbose mode if -verbose is passed
verbose=0
if [[ "$1" == "-verbose" ]]; then
  verbose=1
  shift
fi

# Function to log messages when verbose mode is enabled
log_message() {
  if [[ $verbose -eq 1 ]]; then
    echo "$1"
  fi
}

# Function to deploy configure-host.sh and run it remotely
deploy_config() {
  local server=$1
  local name=$2
  local ip=$3
  local hostentry=$4

  log_message "Deploying to $server..."
  incus file push configure-host.sh "$server/root/configure-host.sh"
  incus exec "$server" -- chmod +x /root/configure-host.sh
  incus exec "$server" -- /root/configure-host.sh -name "$name" -ip "$ip" -hostentry "$hostentry"
}

# Deploy configurations to both containers (server1 and server2)
deploy_config "server1" "loghost" "192.168.16.3" "webhost 192.168.16.4"
deploy_config "server2" "webhost" "192.168.16.4" "loghost 192.168.16.3"

# Update local /etc/hosts (assuming you are executing on the host machine)
log_message "Updating local /etc/hosts"
./configure-host.sh  -hostentry "loghost 192.168.16.3"
./configure-host.sh  -hostentry "webhost 192.168.16.4"

exit 0
