#!/bin/bash

# Prompt for user input
read -p "Enter the desired username: " username
read -sp "Enter the password for $username: " password
echo
read -p "Enter the domain name (e.g., example.com): " domain
read -sp "Enter your Cloudflare API key: " cf_api_key
echo

# Create the user and add to www-data group
sudo useradd -m -s /bin/bash -G www-data $username
echo "$username:$password" | sudo chpasswd

# Set up directory structure
main_web_root="/var/www/$domain"
sudo mkdir -p $main_web_root/{_main/www,subdomains,logs}

# Set ownership and permissions for the main site directory
sudo chown -R $username:www-data $main_web_root
sudo find $main_web_root -type d -exec chmod 2750 {} +
sudo find $main_web_root -type f -exec chmod 640 {} +

# Set ownership and permissions for the logs directory
sudo chown root:www-data $main_web_root/logs
sudo chmod 755 $main_web_root/logs

# Ensure new log files get correct permissions
sudo bash -c "echo '
# Set proper permissions for new log files
umask 022
' >> /etc/nginx/nginx.conf"

# Create Cloudflare credentials file
cf_credentials="/root/.cloudflare/$domain.ini"
sudo mkdir -p /root/.cloudflare
sudo bash -c "cat > $cf_credentials << EOL
dns_cloudflare_api_token = $cf_api_key
EOL"
sudo chmod 600 $cf_credentials

# Request wildcard certificate using Cloudflare DNS challenge
sudo certbot certonly --dns-cloudflare \
    --dns-cloudflare-credentials $cf_credentials \
    -d $domain -d *.$domain \
    --non-interactive

# Create Nginx configuration
nginx_config="/etc/nginx/sites-available/$domain"
sudo bash -c "cat > $nginx_config << EOL
server {
    listen 80;
    listen [::]:80;
    server_name .$domain;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name .$domain;

    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;

    # Determine the subdomain and set the root accordingly
    set \$subdomain '';
    if (\$host ~* ^([^.]+)\.$domain$) {
        set \$subdomain \$1;
    }

    # Default root for subdomains
    root $main_web_root/subdomains/\$subdomain/www;

    # For the main domain, use the _main/www directory
    if (\$host = $domain) {
        root $main_web_root/_main/www;
        access_log $main_web_root/logs/main_access.log;
        error_log $main_web_root/logs/main_error.log;
    }

    # For subdomains, use separate log files
    if (\$subdomain != '') {
        access_log $main_web_root/logs/\${subdomain}_access.log;
        error_log $main_web_root/logs/\${subdomain}_error.log;
    }

    index index.html index.htm index.php;

    location / {
        try_files \$uri \$uri/ @router;
    }

    location @router {
        if (!-f \$document_root/router.php) {
            return 404;
        }
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root/router.php;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL"

# Enable the site
sudo ln -s $nginx_config /etc/nginx/sites-enabled/

# Test Nginx configuration
sudo nginx -t

# If the test is successful, reload Nginx
if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    echo "Nginx configuration has been updated and reloaded."
else
    echo "Nginx configuration test failed. Please check the configuration."
fi

echo "Setup complete for $domain"
echo "Main website files should be placed in: $main_web_root/_main/www"
echo "Subdomain files should be placed in: $main_web_root/subdomains/[subdomain]/www"
echo "Logs will be stored in: $main_web_root/logs"
echo "Cloudflare credentials for this domain are stored in: $cf_credentials"
echo "Remember to log out and log back in for group changes to take effect."
