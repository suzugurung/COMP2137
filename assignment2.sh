#!/bin/bash

# Print starting message
echo "Starting the system configuration script..."

# Function to check and update network configuration
configure_network() {
    echo "Checking network configuration..."
    
    # Netplan file location
    NETPLAN_FILE="/etc/netplan/50-cloud-init.yaml"
    
    # Check if netplan config exists
    if [[ ! -f $NETPLAN_FILE ]]; then
        echo "Error: Netplan configuration file does not exist!"
        exit 1
    fi
    
    # Check for the correct IP address and update if necessary
    if ! grep -q "192.168.16.21" "$NETPLAN_FILE"; then
        echo "Updating network configuration..."
        sudo sed -i 's/192.168.16.*/192.168.16.21\/24/' $NETPLAN_FILE
        echo "Network configuration updated. Applying changes..."
        sudo netplan apply
    else
        echo "Network configuration is already correct."
    fi
}

# Function to update /etc/hosts
update_hosts() {
    echo "Checking /etc/hosts file..."
    
    # Check if the entry for server1 is correct
    if ! grep -q "192.168.16.21 server1" /etc/hosts; then
        echo "Updating /etc/hosts file..."
        sudo sed -i 's/192.168.16.*/192.168.16.21 server1/' /etc/hosts
        echo "Hosts file updated."
    else
        echo "/etc/hosts file is already correct."
    fi
}

# Function to install Apache2 and Squid
install_software() {
    echo "Checking for Apache2 installation..."
    
    # Install Apache2 if not installed
    if ! command -v apache2 &> /dev/null; then
        echo "Apache2 not found. Installing..."
        sudo apt-get update
        sudo apt-get install -y apache2
        echo "Apache2 installed and started."
        sudo systemctl enable apache2
        sudo systemctl start apache2
    else
        echo "Apache2 is already installed."
    fi

    echo "Checking for Squid installation..."
    
    # Install Squid if not installed
    if ! command -v squid &> /dev/null; then
        echo "Squid not found. Installing..."
        sudo apt-get install -y squid
        echo "Squid installed and started."
        sudo systemctl enable squid
        sudo systemctl start squid
    else
        echo "Squid is already installed."
    fi
}

# Function to create users and set up SSH keys
create_users() {
    echo "Creating users and setting up SSH keys..."

    # List of users to create
    USERS=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

    # SSH public keys for each user
    SSH_KEYS=(
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"
    
    )

    # Loop through the users to create them
    for i in "${!USERS[@]}"; do
        USER=${USERS[$i]}
        echo "Checking if user $USER exists..."
        
        # Create the user if it doesn't exist
        if ! id "$USER" &> /dev/null; then
            echo "Creating user $USER..."
            sudo useradd -m -s /bin/bash $USER
            echo "User $USER created."
        else
            echo "User $USER already exists."
        fi
        
        # Set up SSH keys for the user
        echo "Setting up SSH keys for user $USER..."
        sudo mkdir -p /home/$USER/.ssh
        sudo touch /home/$USER/.ssh/authorized_keys
        sudo chmod 700 /home/$USER/.ssh
        sudo chmod 600 /home/$USER/.ssh/authorized_keys
        echo "${SSH_KEYS[$i]}" | sudo tee -a /home/$USER/.ssh/authorized_keys > /dev/null
        sudo chown -R $USER:$USER /home/$USER/.ssh
        echo "SSH keys set up for $USER."
        
        # Add user to sudo group for 'dennis' only
        if [[ $USER == "dennis" ]]; then
            sudo usermod -aG sudo $USER
            echo "$USER added to sudo group."
        fi
    done
}

# Run the functions
configure_network
update_hosts
install_software
create_users

# Print completion message
echo "System configuration completed successfully."
 
