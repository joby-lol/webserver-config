# Web Server Setup Scripts

This repository contains scripts for setting up a very basic web server and adding new sites. It is not perfect, but it will get you off the ground quickly.

This script will install PHP and nginx, and create a 

## One-liner

The following command will install these tools.

It is adviseable to review the contents of `quickstart.sh` before running it, as it's generally a good security practice to understand what a script does before executing it, especially with elevated privileges. You may need to install `curl` first.

```bash
curl -sSL https://raw.githubusercontent.com/joby-lol/webserver-setup/main/quickstart.sh | bash
```
