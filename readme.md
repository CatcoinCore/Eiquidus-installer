
### Catcoin Explorer Installer Ubuntu 20/22/24 ###


Recommended minimum: 2 core server


To avoid package conflicts, it's best to run this installer on a fresh server install


Usage:


1) Server root user:

    " apt update && apt -y upgrade "



2) git clone https://github.com/CatcoinCore/Eiquidus-installer

    cd Eiquidus-installer

    bash install.sh

    Follow on screen prompts


* Service Control

    sudo systemctl start/stop/status catcoind

    sudo systemctl start/stop/status explorer



Explorer url: register a domain name point dns at server ip or use with server ip

http://domain-name.com

http://server-ip

https://domain-name.com -> with Cloudflare
