#!/bin/bash

# Define the log format
LOG_FORMAT="log_format domain_combined '$host \$remote_addr - \$remote_user [\$time_local] \"\$request\" \$status \$body_bytes_sent \"\$http_referer\" \"\$http_user_agent\"';"

# Check if we're root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Define the config file path
CONFIG_FILE="/etc/nginx/conf.d/log-format.conf"

# Create/overwrite the config file
echo "$LOG_FORMAT" > "$CONFIG_FILE"

# Test the nginx config
nginx -t

if [ $? -eq 0 ]; then
    echo "Successfully updated domain_combined log format"
    systemctl restart nginx
else
    echo "Error in nginx config, removing new config..."
    rm "$CONFIG_FILE"
    exit 1
fi
