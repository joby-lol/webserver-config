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

# Restart nginx for good measure
service nginx restart

# Generate SSL certificate
certbot certonly --webroot -w /var/www/default -d $HOSTNAME --agree-tos --register-unsafely-without-email --non-interactive

# Create MySQL SSL directory
mkdir -p /etc/mysql/ssl
chmod 750 /etc/mysql/ssl

# Copy SSL certificates to MySQL directory
cp /etc/letsencrypt/live/$HOSTNAME/fullchain.pem /etc/mysql/ssl/
cp /etc/letsencrypt/live/$HOSTNAME/privkey.pem /etc/mysql/ssl/

# Set proper ownership and permissions
chown -R mysql:mysql /etc/mysql/ssl
chmod 600 /etc/mysql/ssl/*

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
ssl=ON
ssl_cert=/etc/mysql/ssl/fullchain.pem
ssl_key=/etc/mysql/ssl/privkey.pem
require_secure_transport=ON
EOL

# Create certbot renewal hook
mkdir -p /etc/letsencrypt/renewal-hooks/post
cat > /etc/letsencrypt/renewal-hooks/post/mysql-ssl-cert-copy.sh << EOL
#!/bin/bash
cp /etc/letsencrypt/live/$HOSTNAME/fullchain.pem /etc/mysql/ssl/
cp /etc/letsencrypt/live/$HOSTNAME/privkey.pem /etc/mysql/ssl/
chown mysql:mysql /etc/mysql/ssl/*
chmod 600 /etc/mysql/ssl/*
systemctl restart mysql
EOL

chmod +x /etc/letsencrypt/renewal-hooks/post/mysql-ssl-cert-copy.sh

# Restart MySQL to apply changes
systemctl restart mysql

# Create MySQL fail2ban configuration
tee /etc/fail2ban/jail.d/mysql.conf << 'EOL'
[mysql]
enabled = true
filter = mysql
port = 3306
logpath = /var/log/mysql/error.log
maxretry = 20
findtime = 600
bantime = 3600
action = iptables-multiport[name=mysql]
         nginx-banned-ips
EOL

# Create MySQL auth filter for fail2ban
tee /etc/fail2ban/filter.d/mysql.conf << 'EOL'
[Definition]
failregex = ^\s*\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z\s+\d+\s+\[Warning\].*IP address '<HOST>'.*$
ignoreregex =
EOL

# UFW setup
ufw allow 3306/tcp

# Verify SSL is enabled
mysql -e "SHOW VARIABLES LIKE '%ssl%';"

echo "MySQL installation, SSL configuration, and fail2ban setup completed."
