# Web Server Setup Scripts

This repository contains scripts for setting up a very basic web server and adding new sites. It is not perfect, but it will get you off the ground quickly.

## Installation

These commands will clone the tool onto your server and do the basic installation and configuration of core server software. At the moment that is Nginx, PHP, MySQL, and Certbot. A variety of fail2ban and ufw security measures are also added to improve your security posture.

```bash
# clone the repository and cd into it
git clone https://github.com/joby-lol/webserver-config && cd webserver-config && sudo ./install.sh
```

Obviously you should probably at least kind of verify what that script will do before you go executing random code off the internet. You do you though.

## Adding a site

To set up a site, run `add-site.sh` and it will prompt you for all the data necessary. What you will need before running it is:

* A domain name using Cloudflare's DNS, with both @ and * subdomains pointing at your server
  * If you want to use their proxy, you need to turn on the SSL/TLS encryption mode of Full, Full(Strict), or Strict(SSL-Only Origin Pull). Flexible or Off will not work.
* A Cloudflare API key capable of editing the DNS for that domain
