#!/bin/bash

# Function to handle signal ignoring
trap "" SIGTERM SIGINT SIGHUP

# Default values
verbose=0
desiredName=""
desiredIPaddress=""
hostname_entry=""
network_interface=""

# Function for verbose output
verbose_output() {
    if [ "$verbose" -eq 1 ]; then
        echo "$1"
    fi
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -verbose)
            verbose=1
            verbose_output "Verbose mode enabled."
            shift
            ;;
        -name)
            desiredName="$2"
            verbose_output "Desired hostname: $desiredName"
            shift 2
            ;;
        -ip)
            desiredIPaddress="$2"
            verbose_output "Desired IP address: $desiredIPaddress"
            shift 2
            ;;
        -hostentry)
            hostname_entry="$2"
            network_interface="$3"
            verbose_output "Desired host entry: $hostname_entry with IP: $desiredIPaddress"
            shift 3
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$desiredName" ] || [ -z "$desiredIPaddress" ]; then
    echo "Error: -name and -ip arguments are required."
    exit 1
fi

# Update /etc/hosts with desired hostname
if ! grep -q "$desiredName" /etc/hosts; then
    if [ "$verbose" -eq 1 ]; then
        echo "Adding $desiredName to /etc/hosts"
    fi
    sudo sed -i "s/127.0.1.1.*$/127.0.1.1\t$desiredName/" /etc/hosts
    logger "Added $desiredName to /etc/hosts"
else
    verbose_output "$desiredName already exists in /etc/hosts. No changes needed."
fi

# Check if the desired IP address is assigned to the correct network interface
if [ -n "$network_interface" ]; then
    interface_ip=$(ip addr show "$network_interface" | grep inet | awk '{ print $2 }' | cut -d/ -f1)
    if [ "$interface_ip" != "$desiredIPaddress" ]; then
        if [ "$verbose" -eq 1 ]; then
            echo "Changing IP address on $network_interface from $interface_ip to $desiredIPaddress"
        fi
        # Update the netplan configuration
        sudo sed -i "s/$interface_ip/$desiredIPaddress/" /etc/netplan/*.yaml
        sudo netplan apply
        logger "IP address on $network_interface changed to $desiredIPaddress"
    else
        verbose_output "IP address on $network_interface is already set to $desiredIPaddress."
    fi
else
    verbose_output "Network interface not specified. Skipping IP address update."
fi

# Check if the desired host entry exists in /etc/hosts
if [ -n "$hostname_entry" ]; then
    if ! grep -q "$hostname_entry" /etc/hosts; then
        if [ "$verbose" -eq 1 ]; then
            echo "Adding host entry $hostname_entry to /etc/hosts"
        fi
        echo "$desiredIPaddress $hostname_entry" | sudo tee -a /etc/hosts > /dev/null
        logger "Added $hostname_entry with IP $desiredIPaddress to /etc/hosts"
    else
        verbose_output "Host entry $hostname_entry already exists in /etc/hosts. No changes needed."
    fi
else
    verbose_output "No host entry specified. Skipping host entry update."
fi

# End of script
echo "Configuration complete."

