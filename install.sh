#!/bin/bash

# Core Setup Script for Web Server
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Set up logging
LOG_FILE="/var/log/server_setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Installation started at $(date)"

# run additional scripts from install/
INSTALL_DIR="./install"

# Check if install directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Error: $INSTALL_DIR directory not found"
    exit 1
fi

# Make all .sh files in the install directory executable
find "$INSTALL_DIR" -name "*.sh" -type f -exec chmod +x {} \;

# Function to run scripts in a directory
run_scripts() {
    for script in "$1"/*.sh; do
        if [ -f "$script" ]; then
            echo "Running $script..."
            if [ -z "$SKIP_SCRIPT" ] || [[ "$SKIP_SCRIPT" != *"$(basename "$script")"* ]]; then
                bash "$script"
                if [ $? -ne 0 ]; then
                    echo "Error executing $script"
                    exit 1
                fi
            else
                echo "Skipping $script"
            fi
        fi
    done
}

# Run all scripts in the install directory
run_scripts "$INSTALL_DIR"

# Start and enable key services
for service in mysql nginx fail2ban; do
    echo "Restarting $service..."
    sudo systemctl restart $service
    sudo systemctl enable $service
done

# Output completion messages
echo "Core setup completed successfully at $(date)"
echo "You can now use add_site.sh to add new users/sites"
echo "For more details, check the log file at $LOG_FILE"
