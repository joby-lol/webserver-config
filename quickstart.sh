#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Update package list
sudo apt update

# Install curl and git
sudo apt install -y curl git

# Clone the repository
git clone https://github.com/joby-lol/webserver-config.git

# Change to the repository directory
cd webserver-config

# Make install-server.sh executable
chmod +x install-server.sh

# Execute install-server.sh
sudo ./install-server.sh

echo "Server setup complete. Use 'sudo bash add_site.sh' to add new sites."
