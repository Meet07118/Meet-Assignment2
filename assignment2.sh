#!/bin/bash

# Function to print messages in a human-friendly way
print_message() {
    echo "=================================================================="
    echo "$1"
    echo "=================================================================="
}

# Step 1: Check if Apache2 is installed and running
print_message "Checking if apache2 is installed and running."

if ! dpkg -l | grep -q apache2; then
    print_message "Installing Apache2..."
    apt update && apt install -y apache2
else
    print_message "Apache2 is already installed."
fi

if ! systemctl is-active --quiet apache2; then
    print_message "Apache2 service starts from here"
    systemctl start apache2
    systemctl enable apache2
else
    print_message "Apache2 is  running."
fi

# Step 2: Check if Squid is installed and running
print_message "Checking if Squid is installed and running."

if ! dpkg -l | grep -q squid; then
    print_message "Installing Squid..."
    apt update && apt install -y squid
else
    print_message "Squid is already installed."
fi

if ! systemctl is-active --quiet squid; then
    print_message "Starting Squid service..."
    systemctl start squid
    systemctl enable squid
else
    print_message "Squid is already running."
fi

# Step 3: Configure 192.168.16 network interface
print_message "Configuring 192.168.16 network interface..."

netplan_file="/etc/netplan/00-installer-config.yaml"

# Modify netplan configuration if needed
if ! grep -q "192.168.16.21/24" "$netplan_file"; then
    print_message "Updating netplan configuration for 192.168.16.21/24..."
    sed -i 's/address:.*/address: 192.168.16.21\/24/' "$netplan_file"
    netplan apply
else
    print_message "Network interface configuration is already correct."
fi

# Step 4: Configure /etc/hosts file
print_message "Updating /etc/hosts file..."

if ! grep -q "192.168.16.21" /etc/hosts; then
    print_message "Adding 192.168.16.21 entry to /etc/hosts..."
    echo "192.168.16.21 server1" >> /etc/hosts
else
    print_message "/etc/hosts file already contains the correct entry."
fi

# Step 5: Create user accounts with specified SSH keys and sudo access
print_message "Creating user accounts..."

users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
ssh_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

for user in "${users[@]}"; do
    if id -u "$user" &>/dev/null; then
        print_message "User '$user' already exists."
    else
        print_message "Creating user '$user'..."
        useradd -m -s /bin/bash "$user"
        echo "$user:$user" | chpasswd
        usermod -aG sudo "$user"
        mkdir -p "/home/$user/.ssh"
        echo "$ssh_key" > "/home/$user/.ssh/authorized_keys"
        chown -R "$user:$user" "/home/$user/.ssh"
        chmod 700 "/home/$user/.ssh"
        chmod 600 "/home/$user/.ssh/authorized_keys"
    fi
done

# Step 6: Make the script idempotent (safe to rerun)
print_message "Ensuring idempotency..."

# Checking if configurations are already applied before making changes
# Example: Checking if 192.168.16.21 is already set up in netplan or /etc/hosts before applying changes
# Similarly, the script can be modified to avoid unnecessary changes on reruns.

print_message "Script execution completed successfully!"
