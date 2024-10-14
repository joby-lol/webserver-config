#!/bin/bash

# Core Setup Script for Web Server

# Update and upgrade packages
sudo apt update
sudo apt upgrade -y

# Install Nginx and UFW
sudo apt install nginx ufw -y

# Install PHP and necessary modules
sudo apt install php-fpm php-curl php-gd php-mbstring php-xml php-zip php-pdo php-sqlite3 -y

# Start and enable PHP-FPM service
sudo systemctl start php-fpm
sudo systemctl enable php-fpm

# Ensure Nginx is started and enabled
sudo systemctl start nginx
sudo systemctl enable nginx

# UFW Setup
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# Swap Setup
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make swap permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Adjust swappiness
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Install Certbot and Cloudflare plugin
sudo apt install certbot python3-certbot-dns-cloudflare -y

# Prompt user for email address
read -p "Enter your email address for Certbot registration: " email_address

# Register with Certbot
sudo certbot register --email "$email_address" --agree-tos --no-eff-email

# Create post-renewal hook for Nginx reload
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy
sudo bash -c "cat > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh << EOL
#!/bin/bash
systemctl reload nginx
EOL"
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh

# Verify auto-renewal configuration
echo "Verifying Certbot auto-renewal configuration..."
sudo certbot renew --dry-run

echo "Core setup completed successfully!"
echo "Certbot has been registered with the provided email address"
echo "A post-renewal hook has been added to reload Nginx after certificate renewal"
echo "Auto-renewal has been verified. If you saw no errors, it's correctly set up."
echo "UFW has been configured and enabled"
echo "A 2GB swap file has been set up and configured"
