#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Name of the new group
NEW_GROUP="websftpusers"

# Create the new group
if ! getent group $NEW_GROUP > /dev/null 2>&1; then
    groupadd $NEW_GROUP
    echo "Group $NEW_GROUP created successfully."
else
    echo "Group $NEW_GROUP already exists."
fi

# Check if sshd_config.d directory exists, create if it doesn't
SSHD_CONFIG_DIR="/etc/ssh/sshd_config.d"
if [ ! -d "$SSHD_CONFIG_DIR" ]; then
    mkdir -p "$SSHD_CONFIG_DIR"
    echo "Created $SSHD_CONFIG_DIR directory."

    # Ensure the main sshd_config includes the .d directory
    if ! grep -q "Include /etc/ssh/sshd_config.d/\*.conf" /etc/ssh/sshd_config; then
        echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
        echo "Added include directive to main sshd_config."
    fi
fi

# Create a new configuration file for websftpusers
CONFIG_FILE="$SSHD_CONFIG_DIR/websftpusers.conf"

cat << EOF > "$CONFIG_FILE"
# Configuration for $NEW_GROUP
Match Group $NEW_GROUP
    ChrootDirectory %h
    ForceCommand internal-sftp
    PasswordAuthentication yes
    PermitTunnel no
    AllowAgentForwarding no
    AllowTcpForwarding no
    X11Forwarding no
EOF

echo "Created $CONFIG_FILE with $NEW_GROUP configuration."

# Restart SSH service to apply changes
systemctl restart ssh
echo "SSH service restarted to apply changes."

echo "Setup complete. New group $NEW_GROUP has been created and SSHD configured for SFTP access."
