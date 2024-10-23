#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Install Certbot and Cloudflare plugin
sudo apt install certbot python3-certbot-dns-cloudflare -y

# Create post-renewal hook for Nginx reload
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy
sudo bash -c "cat > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh << EOL
#!/bin/bash
systemctl reload nginx
EOL"
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh