#!/bin/bash

# Core Setup Script for Web Server
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit
fi

# Update and upgrade packages
sudo apt update
sudo apt upgrade -y

# Install Nginx, UFW, MySQL, and fail2ban
sudo apt install nginx ufw mysql-server fail2ban -y

# Install PHP and necessary modules
sudo apt install php-fpm php-curl php-gd php-mbstring php-xml php-zip php-pdo php-mysql php-sqlite3 -y

# UFW Setup
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# Swap Setup
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make swap permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Adjust swappiness
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Install Certbot and Cloudflare plugin
sudo apt install certbot python3-certbot-dns-cloudflare -y

# Create post-renewal hook for Nginx reload
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy
sudo bash -c "cat > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh << EOL
#!/bin/bash
systemctl reload nginx
EOL"
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh

# Configure MySQL for Unix socket authentication
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH auth_socket;"
sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
sudo mysql -e "DROP DATABASE IF EXISTS test;"
sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Enable MySQL error logging
sudo sed -i '/^\[mysqld\]/a log_error = /var/log/mysql/error.log' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

# Configure fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Copy custom fail2ban configuration
sudo cp fail2ban.conf /etc/fail2ban/jail.d/custom.conf

# Ensure fail2ban can read the MySQL log
sudo usermod -a -G adm fail2ban

# Create MySQL auth filter for fail2ban
sudo bash -c "cat > /etc/fail2ban/filter.d/mysqld-auth.conf << EOL
[Definition]
failregex = ^%(__prefix_line)s[0-9]+ \[Warning\] Access denied for user '\w+'@'<HOST>'
ignoreregex =
EOL"

# Create phpMyAdmin filter for fail2ban
sudo bash -c "cat > /etc/fail2ban/filter.d/phpmyadmin.conf << EOL
[Definition]
failregex = ^<HOST> .* \"(GET|POST) /phpmyadmin/index\.php HTTP/.*\" 403
            ^<HOST> .* \"(GET|POST) /phpmyadmin/.* HTTP/.*\" 404
ignoreregex =
EOL"

# Install phpMyAdmin
sudo apt install phpmyadmin -y

# Configure phpMyAdmin with Nginx
sudo bash -c "cat > /etc/nginx/conf.d/phpmyadmin.conf << EOL
location /phpmyadmin {
    root /usr/share/;
    index index.php index.html index.htm;
    location ~ ^/phpmyadmin/(.+\.php)$ {
        try_files \$uri =404;
        root /usr/share/;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
        access_log /var/log/nginx/phpmyadmin_access.log;
    }
    location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
        root /usr/share/;
    }
}
EOL"

# Start and enable MySQL
sudo systemctl start mysql
sudo systemctl enable mysql

# Start and enable PHP-FPM service
sudo systemctl start php-fpm
sudo systemctl enable php-fpm

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Start and enable fail2ban
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

# Output completion messages
echo "Core setup completed successfully!"
echo "Nginx, PHP, MySQL, fail2ban, and phpMyAdmin have been installed and configured"
echo "Certbot and its Cloudflare plugin have been installed"
echo "A post-renewal hook has been added to reload Nginx after certificate renewal"
echo "UFW has been configured and enabled"
echo "A 2GB swap file has been set up and configured"
echo "MySQL has been configured for Unix socket authentication (no password, command-line only for root)"
echo "fail2ban has been configured to protect SSH, Nginx HTTP authentication, and MySQL"
echo "phpMyAdmin has been installed and configured with Nginx"
echo "You can access phpMyAdmin at http://your_server_ip/phpmyadmin"
echo "You can now use 'sudo bash add_site.sh' to add new sites and configure SSL for each"
