
### Catcoin explorer auto installer script Ubuntu 20/22/24 ###


Usage:


1) Create user

   " sudo adduser explorer "

   " sudo usermod -aG sudo explorer "

   " Logout root: type 'exit' press enter "

   " Login: ssh explorer@server ip "


2) git clone https://github.com/CatcoinCore/Eiquidus-installer

3) Start installation:

   cd Eiquidus-installer

   chmod +x install.sh dependencies.sh

   ./install.sh


* When completed - open explorer process "screen -r explorer"

* Never exit this screen it’s the explorer main process

* close screen with "ctrl+a+d"


Explorer url: register a domain name point at server ip or use with server ip

http://domain-name.com

http://server-ip
