#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

echo "Setting up fail2ban for Nginx errors with strict, moderate, and lenient jails..."

# Create the filter files
cat > /etc/fail2ban/filter.d/nginx-4xx-strict.conf << EOL
[Definition]
failregex = ^<HOST> .* "(GET|POST|HEAD|PUT|DELETE|CONNECT|OPTIONS|TRACE|PATCH).*" (401|403) .*$
ignoreregex =
EOL

cat > /etc/fail2ban/filter.d/nginx-4xx-moderate.conf << EOL
[Definition]
failregex = ^<HOST> .* "(GET|POST|HEAD|PUT|DELETE|CONNECT|OPTIONS|TRACE|PATCH).*" (400|405|406|408|413|444) .*$
ignoreregex =
EOL

cat > /etc/fail2ban/filter.d/nginx-4xx-lenient.conf << EOL
[Definition]
failregex = ^<HOST> .* "(GET|POST|HEAD|PUT|DELETE|CONNECT|OPTIONS|TRACE|PATCH).*" (404|429) .*$
ignoreregex =
EOL

# Create a new jail configuration file in jail.d
cat > /etc/fail2ban/jail.d/nginx-4xx-jails.conf << EOL
[nginx-4xx-strict]
enabled = true
port = http,https
filter = nginx-4xx-strict
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 600
bantime = 3600

[nginx-4xx-moderate]
enabled = true
port = http,https
filter = nginx-4xx-moderate
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 600
bantime = 1800

[nginx-4xx-lenient]
enabled = true
port = http,https
filter = nginx-4xx-lenient
logpath = /var/log/nginx/access.log
maxretry = 20
findtime = 600
bantime = 900
EOL

echo "fail2ban setup for Nginx errors completed with strict, moderate, and lenient jails."
