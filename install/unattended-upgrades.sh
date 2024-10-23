#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Exit if unattended-upgrades is already installed
if dpkg -l unattended-upgrades > /dev/null; then
    echo "unattended-upgrades is already installed"
    exit 0
fi

# Install unattended-upgrades
sudo apt install unattended-upgrades apt-listchanges -y

# Configure unattended-upgrades silently
sudo bash -c "cat > /etc/apt/apt.conf.d/20auto-upgrades << EOL
APT::Periodic::Update-Package-Lists \"1\";
APT::Periodic::Unattended-Upgrade \"1\";
APT::Periodic::AutocleanInterval \"7\";
Unattended-Upgrade::Remove-Unused-Dependencies \"true\";
Unattended-Upgrade::Automatic-Reboot \"true\";
EOL"

# Configure which updates to automatically install
sudo bash -c "cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOL
Unattended-Upgrade::Allowed-Origins {
    \"\${distro_id}:\${distro_codename}\";
    \"\${distro_id}:\${distro_codename}-security\";
    \"\${distro_id}ESMApps:\${distro_codename}-apps-security\";
    \"\${distro_id}ESM:\${distro_codename}-infra-security\";
};
Unattended-Upgrade::Package-Blacklist {
    // Add packages here that you don't want to be automatically upgraded
};
EOL"
