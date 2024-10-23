#!/bin/bash

# Define the log format (all on one line)
LOG_FORMAT="log_format domain_combined '$host \$remote_addr - \$remote_user [\$time_local] \"\$request\" \$status \$body_bytes_sent \"\$http_referer\" \"\$http_user_agent\"';"

# Check if we're root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Backup the original config
if ! cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak; then
    echo "Failed to create backup"
    exit 1
fi

# Check if format already exists
if grep -q "log_format domain_combined" /etc/nginx/nginx.conf; then
    echo "domain_combined format already exists"
    exit 0
fi

# Add the format after the first 'http {' line
sed -i "/^http {/a \    ${LOG_FORMAT}" /etc/nginx/nginx.conf

# Test the nginx config
nginx -t

if [ $? -eq 0 ]; then
    echo "Successfully added domain_combined log format"
else
    echo "Error in nginx config, reverting..."
    mv /etc/nginx/nginx.conf.bak /etc/nginx/nginx.conf
    exit 1
fi
