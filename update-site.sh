#!/bin/bash

# Script to update Nginx configuration for an existing site
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Set up logging
LOG_FILE="/var/log/site_setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Configuration update started at $(date)"
echo "Logging to $LOG_FILE"

# Prompt for domain input
read -p "Enter the domain name (e.g., example.com): " domain
if [[ ! "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "Invalid domain name format"
    exit 1
fi

# Verify domain exists in Nginx config
if [ ! -f "/etc/nginx/sites-available/$domain" ]; then
    echo "Error: Domain configuration not found in /etc/nginx/sites-available/$domain"
    exit 1
fi

# Verify SSL certificates exist
if [ ! -d "/etc/letsencrypt/live/$domain" ]; then
    echo "Error: SSL certificates not found for $domain"
    exit 1
fi

# Create nginx config directory in web root
NGINX_CONF_DIR="/var/www/$domain/nginx"
if [ ! -d "$NGINX_CONF_DIR" ]; then
    echo "Creating nginx configuration directory..."
    mkdir -p "$NGINX_CONF_DIR"
    chown root:www-data "$NGINX_CONF_DIR"
    chmod 750 "$NGINX_CONF_DIR"
    # Only try to chmod files if they exist
    if [ "$(ls -A $NGINX_CONF_DIR)" ]; then
        chmod 640 "$NGINX_CONF_DIR"/*
    fi
    echo "Created $NGINX_CONF_DIR with secure permissions"
fi

# Backup existing configuration
backup_file="/etc/nginx/sites-available/${domain}.backup-$(date +%Y%m%d-%H%M%S)"
cp "/etc/nginx/sites-available/$domain" "$backup_file"
echo "Backed up existing configuration to $backup_file"

# Copy new Nginx configuration from adjacent file
nginx_config="/etc/nginx/sites-available/$domain"
cp "$(realpath "site-config.conf")" "$nginx_config"

# Replace $DOMAIN placeholder in the nginx config file
sed -i "s/\$DOMAIN/$domain/g" "$nginx_config"

# Test Nginx configuration
echo "Testing new configuration..."
nginx -t
if [ $? -ne 0 ]; then
    echo "Error: Invalid Nginx configuration. Restoring backup..."
    cp "$backup_file" "$nginx_config"
    exit 1
fi

# Reload nginx
systemctl reload nginx

echo "Configuration update complete for $domain"
echo "Previous configuration backed up to: $backup_file"
echo "Site-specific nginx configurations can be added in: $NGINX_CONF_DIR"
