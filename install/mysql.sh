#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Auto-detect hostname
HOSTNAME=$(hostname -f)

# Install MySQL and Certbot
apt install mysql-server certbot -y

# Generate SSL certificate
certbot certonly --webroot -w /var/www/default -d $HOSTNAME --agree-tos --register-unsafely-without-email --non-interactive

# Configure MySQL for Unix socket authentication
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH auth_socket;"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -e "FLUSH PRIVILEGES;"

# Allow remote MySQL access (users who can access it this way are added later)
sed -i 's/^bind-address\s*=\s*127\.0\.0\.1/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

# Enable MySQL error logging
sed -i '/^\[mysqld\]/a log_error = /var/log/mysql/error.log' /etc/mysql/mysql.conf.d/mysqld.cnf

# Create a separate file for SSL configuration
cat > /etc/mysql/mysql.conf.d/ssl.cnf << EOL
[mysqld]
# SSL Configuration
ssl-ca=/etc/letsencrypt/live/$HOSTNAME/chain.pem
ssl-cert=/etc/letsencrypt/live/$HOSTNAME/cert.pem
ssl-key=/etc/letsencrypt/live/$HOSTNAME/privkey.pem
require_secure_transport=ON
EOL

# Restart MySQL to apply changes
systemctl restart mysql

# Create MySQL fail2ban configuration
tee /etc/fail2ban/jail.d/mysql.conf << 'EOL'
[mysql]
enabled = true
filter = mysql
port = 3306
logpath = /var/log/mysql/error.log
maxretry = 10
findtime = 600
bantime = 3600
action = iptables-multiport[name=mysql]
         nginx-banned-ips
EOL

# Ensure fail2ban can read the MySQL log
# Note: maybe not necessary on Ubuntu, as fail2ban runs as root
# usermod -a -G adm fail2ban

# Create MySQL auth filter for fail2ban
tee /etc/fail2ban/filter.d/mysql.conf << 'EOL'
[Definition]
failregex = ^\s*\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z\s+\d+\s+\[Warning\].*IP address '<HOST>'.*$
ignoreregex =
EOL

# UFW setup
ufw allow 3306/tcp

echo "MySQL installation, SSL configuration, and fail2ban setup completed."
