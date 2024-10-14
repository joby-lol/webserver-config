#!/bin/bash

# Script to quickly set up a new server
# Download and install by running:
# curl -sSL https://raw.githubusercontent.com/joby-lol/webserver-config/refs/heads/main/quickstart.sh | bash
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit
fi

# Update package list
sudo apt update

# Install curl and git
sudo apt install -y git

# Clone the repository
git clone https://github.com/joby-lol/webserver-config.git

# Change to the repository directory
cd webserver-config

# Execute install-server.sh
sudo ./install-server.sh

echo "Server setup complete. Use 'sudo ./add_site.sh' to add new sites."
