# Web Server Setup Scripts

This repository contains scripts for setting up a very basic web server and adding new sites. It is not perfect, but it will get you off the ground quickly.

This script will install PHP and nginx, and create a 

## One-liner

The following command will install these tools.

It is adviseable to review the contents of `quickstart.sh` before running it, as it's generally a good security practice to understand what a script does before executing it, especially with elevated privileges. You may need to install `curl` first.

```bash
curl -sSL https://raw.githubusercontent.com/joby-lol/webserver-config/refs/heads/main/quickstart.sh | bash
```
## Adding a site

To set up a site, run `add-site.sh` and it will prompt you for all the data necessary. What you will need before running it is:

* A domain name using Cloudflare's DNS, with both @ and * subdomains pointing at your server
  * If you want to use their proxy, you need to turn on the SSL/TLS encryption mode of Full, Full(Strict), or Strict(SSL-Only Origin Pull). Flexible or Off will not work.
* A Cloudflare API key capable of editing the DNS for that domain
