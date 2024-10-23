#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Install requirements
echo "Installing required packages..."
apt-get install -y nginx-extras

# Create the fail2ban check script
echo "Creating fail2ban check script..."
tee /usr/local/bin/check_fail2ban.sh << 'SCRIPT'
#!/bin/bash
IP="$1"
# Get list of all active jails
JAILS=$(fail2ban-client status | grep "Jail list:" | sed "s/^[^:]*:[ \t]*//" | sed "s/,//g")

# Check each jail for the IP
for JAIL in $JAILS; do
    if fail2ban-client status "$JAIL" | grep -q "IP list:\s*.*$IP"; then
        exit 0  # IP is banned in at least one jail
    fi
done
exit 1  # IP is not banned in any jail
SCRIPT
chmod +x /usr/local/bin/check_fail2ban.sh
chown www-data:www-data /usr/local/bin/check_fail2ban.sh

# Create the JavaScript module for NGINX
echo "Creating NGINX JavaScript module..."
mkdir -p /etc/nginx/modules-available/
tee /etc/nginx/modules-available/check_ban.js << 'JSMODULE'
function checkBan(r) {
    var ip = r.variables.http_cf_connecting_ip;
    var s = require('process').spawnSync('/usr/local/bin/check_fail2ban.sh', [ip]);
    return s.status === 0 ? '1' : '0';
}

export default {checkBan};
JSMODULE

# Test NGINX configuration
echo "Testing NGINX configuration..."
nginx -t

# Restart services
echo "Restarting services..."
systemctl restart fail2ban
systemctl restart nginx

echo "Installation complete!"
echo "Please check /var/log/nginx/error.log for any issues."
