#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Set up a default nginx site in /var/www/default
echo "Setting up default Nginx site in /var/www/default..."

# Create the directory for the default site
mkdir -p /var/www/default

# Create a simple HTML file for the default site
cat > /var/www/default/index.html << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Default Site</title>
</head>
<body>
    <h1>Nothing here</h1>
    <p>There is nothing here</p>
</body>
</html>
EOL

# Create the Nginx server block configuration for the default site
cat > /etc/nginx/sites-available/default << EOL
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/default;
    index index.html;

    server_name _;

    # Apply general rate limit
    limit_req zone=general burst=100 nodelay;

    # Check for banned IPs
    if (\$is_banned) {
        return 403;
    }

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

# Enable the default site
ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Reload Nginx to apply changes
systemctl reload nginx

echo "Default Nginx site has been set up and enabled."
