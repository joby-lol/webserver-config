#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Create banned IPs file
echo "Creating banned IPs file..."
touch /etc/nginx/conf.d/banned_ips.conf
chown www-data:www-data /etc/nginx/conf.d/banned_ips.conf

# Create NGINX configuration for fail2ban check
echo "Creating NGINX configuration..."
tee /etc/nginx/conf.d/10-fail2ban-check.conf << 'CONFFILE'
map $http_cf_connecting_ip $is_banned {
    default 0;
    include /etc/nginx/conf.d/banned_ips.conf;
}
CONFFILE

# Create fail2ban action
echo "Creating fail2ban action..."
tee /etc/fail2ban/action.d/nginx-banned-ips.conf << 'ACTIONFILE'
[Definition]
actionstart = 
actionstop = 
actioncheck = 
actionban = echo '<ip> 1;' >> /etc/nginx/conf.d/banned_ips.conf && nginx -s reload
actionunban = sed -i '/<ip>/d' /etc/nginx/conf.d/banned_ips.conf && nginx -s reload
ACTIONFILE

# Test NGINX configuration
echo "Testing NGINX configuration..."
nginx -t

echo "Installation complete!"
echo "Now add 'nginx-banned-ips' to the action line in your existing fail2ban jail configurations"
