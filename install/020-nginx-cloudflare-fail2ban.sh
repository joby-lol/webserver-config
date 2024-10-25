#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Create maps directory if it doesn't exist
echo "Creating maps directory..."
mkdir -p /etc/nginx/maps

# Create banned IPs file
echo "Creating banned IPs file..."
touch /etc/nginx/maps/banned_ips.conf
chown www-data:www-data /etc/nginx/maps/banned_ips.conf

# Create NGINX configuration for fail2ban check
echo "Creating NGINX configuration..."
tee /etc/nginx/conf.d/10-fail2ban-check.conf << 'CONFFILE'
map $http_cf_connecting_ip $is_banned {
    default 0;
    volatile;
    include /etc/nginx/maps/banned_ips.conf;
}
CONFFILE

# Create fail2ban action
cat > /etc/fail2ban/action.d/nginx-banned-ips.conf << 'ACTIONFILE'
[Definition]
actionstart = 
actionstop = 
actioncheck = 
actionban = grep -q '^<ip> 1;$' /etc/nginx/maps/banned_ips.conf || echo '<ip> 1;' >> /etc/nginx/maps/banned_ips.conf && nginx -s reload
actionunban = sed -i '/^<ip> 1;$/d' /etc/nginx/maps/banned_ips.conf && nginx -s reload
ACTIONFILE

# Reload nginx
service nginx reload

echo "Installation complete!"
echo "Now add 'nginx-banned-ips' to the action line in your existing fail2ban jail configurations"
