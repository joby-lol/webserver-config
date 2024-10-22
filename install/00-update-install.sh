#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Update and upgrade packages
apt update
apt upgrade -y

# Install Nginx, UFW, NTP, and fail2ban
apt install nginx ufw ntp fail2ban -y

# Install PHP and necessary modules
apt install php-fpm php-curl php-gd php-mbstring php-xml php-zip php-pdo php-mysql php-sqlite3 -y

# Set timezone
timedatectl set-timezone UTC

# UFW Setup
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 'Nginx Full'
ufw --force enable

# Create custom fail2ban configuration
cat > /etc/fail2ban/jail.d/server.conf << EOL
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 10
bantime = 86400

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 5
bantime = 3600
EOL

# SSH hardening
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh

# Ensure fail2ban jail.local exists
if [ ! -f /etc/fail2ban/jail.local ]; then
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
fi

# Restart fail2ban to apply changes
systemctl restart fail2ban

echo "Server setup and fail2ban configuration completed."