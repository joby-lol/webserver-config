#!/bin/bash

# Script to add a site to the server
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Set up logging
LOG_FILE="/var/log/site_setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Installation started at $(date)"
echo "Logging to $LOG_FILE"

# Prompt for user input
read -p "Enter the desired username: " username
read -p "Enter the domain name (e.g., example.com): " domain
if [[ ! "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "Invalid domain name format"
    exit 1
fi
read -p "Enter the email address to be used for this account: " email
if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "Invalid email format"
    exit 1
fi
read -sp "Enter your Cloudflare API key: " cf_api_key
echo

# Generated passwords
password=$(openssl rand -base64 12)
mysql_password=$(openssl rand -base64 12)

# Get hostname or IP
hostname=$(hostname -f)

# Set up directory structure
main_web_root="/var/www/$domain"
sudo mkdir -p "$main_web_root"/{_main/www,subdomains,logs}

# Create the user with the web root as home directory and add to www-data and websftpusers groups
sudo useradd -m -d /var/www/$domain -s /bin/false -U -G www-data,websftpusers $username
echo "$username:$password" | sudo chpasswd

# Set ownership and permissions for the main site directory
sudo chown -R "$username:www-data" "$main_web_root"
sudo find "$main_web_root" -type d -exec chmod 2750 {} +
sudo find "$main_web_root" -type f -exec chmod 640 {} +

# Set ownership and permissions for the main web root
# SFTP chroot requires the user's home directory to be owned by root and not writable by others
sudo chown "root:www-data" "$main_web_root"
sudo chmod 755 "$main_web_root"

# Set ownership and permissions for the logs directory
sudo chown root:www-data "$main_web_root/logs"
sudo chmod 755 "$main_web_root/logs"

# Create MySQL user and grant permissions
sudo mysql <<EOF
CREATE USER IF NOT EXISTS '${username}'@'localhost' IDENTIFIED BY '${mysql_password}';
CREATE USER IF NOT EXISTS '${username}'@'%' IDENTIFIED BY '${mysql_password}';
GRANT ALL PRIVILEGES ON \`${username}_%\`.* TO '${username}'@'localhost';
GRANT ALL PRIVILEGES ON \`${username}_%\`.* TO '${username}'@'%';
GRANT CREATE USER ON *.* TO '${username}'@'localhost' WITH GRANT OPTION;
GRANT CREATE USER ON *.* TO '${username}'@'%' WITH GRANT OPTION;
GRANT ROLE_ADMIN ON *.* TO '${username}'@'localhost';
GRANT ROLE_ADMIN ON *.* TO '${username}'@'%';
FLUSH PRIVILEGES;
EOF

# Create site info file
info_file="$main_web_root/site_info.txt"
sudo bash -c "cat > \"$info_file\" << EOL
Domain: $domain
Email: $email

SFTP Host: $hostname
Username: $username
Password: $password

MySQL Username: $username
MySQL Password: $mysql_password
MySQL Host: $hostname
EOL"
sudo chown "$username:$username" "$info_file"
sudo chmod 600 "$info_file"

# Create Cloudflare credentials file
cf_credentials="$main_web_root/cloudflare.ini"
sudo bash -c "cat > \"$cf_credentials\" << EOL
dns_cloudflare_api_token = $cf_api_key
EOL"
sudo chown root:root "$cf_credentials"
sudo chmod 600 "$cf_credentials"

# Request wildcard certificate using Cloudflare DNS challenge
sudo certbot certonly --dns-cloudflare \
    --dns-cloudflare-credentials "$cf_credentials" \
    -d "$domain" -d "*.$domain" \
    --non-interactive \
    --agree-tos \
    --email "$email"

# Copy Nginx configuration from adjacent file
nginx_config="/etc/nginx/sites-available/$domain"
sudo cp "$(realpath "site-config.conf")" "$nginx_config"

# replace $DOMAIN placeholder in the nginx config file
sudo sed -i "s/\$DOMAIN/$domain/g" "$nginx_config"

# Enable the site
sudo ln -sf "$nginx_config" /etc/nginx/sites-enabled/

# Enable log rotation
sudo tee /etc/logrotate.d/"$domain" > /dev/null <<EOL
$main_web_root/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    dateext
    dateformat -%Y-%m-%d
    size 100M
    postrotate
        /usr/sbin/invoke-rc.d nginx rotate >/dev/null 2>&1
    endscript
}
EOL

# Reload nginx
sudo systemctl reload nginx

echo "Setup complete for $domain"
echo "Access via SFTP at $hostname with the username $username and the password $password"
echo "Main website files should be placed in: _main/www"
echo "Subdomain files should be placed in: subdomains/[subdomain]/www"
echo "Site information (including MySQL credentials) is stored in: $info_file"
echo "Cloudflare credentials for this domain are stored in: $cf_credentials"
echo "Logs are stored in: logs"
