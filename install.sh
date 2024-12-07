#!/usr/bin/env bash
current_dir=$PWD
current_user=$USER
explorer_dir=""
cat_dir=""

# Verify the installer has not been invoked as root user #
if [[ $EUID == 0 ]]; then
   echo ""
   echo " * Creating explorer user. *"
   echo ""
   echo " * Please write down or remember the password & follow on screen prompts. *"
   echo ""
   sleep 10
   adduser explorer
   usermod -aG sudo explorer
   cp -R /root/Eiquidus-installer /home/explorer/Eiquidus-installer
   chown -R explorer:explorer /home/explorer/Eiquidus-installer
   chmod -R 755 /home/explorer/Eiquidus-installer
   echo ""
   echo " * Logout root: type 'exit' press enter *"
   echo ""
   echo " * Login: ssh explorer@server ip *"
   echo ""
   echo " * Start setup: cd Eiquidus-installer && bash install.sh *"
   echo ""
   exit 1
fi

printf "\n"
printf "\n"
printf " ** Welcome to Catcoin Explorer Setup! **\n"
printf "\n"
printf " This script has been tested on Ubuntu 20/22/24 server.\n"
printf "\n"
printf " First we will check prerequisite packages are installed.\n"
printf "\n"
read -p " Press Enter to Continue..."$'\n' Continue

sudo bash dependencies.sh > install.log &
dependencies_pid=$!
printf "\nSystem build packages install...\n"
printf "\nBuilding boost plus installing additional packages...\n"
printf "\nThis will take a long time 10-15 minutes... Minimal output... Please wait patiently...\n"
printf "\n"
wait $dependencies_pid
# Check if exit status was non-zero #
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Installing dependencies failed. Check the install.log file for more information."
    exit 1
fi

printf "\nCloning repositories - Catcoin and Eiquidus...\n"
printf "\n"
cd $current_dir
git clone https://github.com/CatcoinCore/Catcoin-v0.9.3.0.git
cd ~/
git clone https://github.com/CatcoinCore/eiquidus.git -b CatCoin

# Build Catcoin #
printf "\n"
printf "\nBuilding Catcoin wallet... This will take some time 5-10 minutes... Please wait patiently...\n"
cd $current_dir/Catcoin-v0.9.3.0/src
{
make -f makefile.unix
} > /dev/null 2>&1
strip catcoind
mkdir ~/coinds
cp catcoind ~/coinds/catcoind

# wallet config #
mkdir ~/.catcoin
cd $current_dir
cp config/catcoin ~/.catcoin/catcoin.conf

# Catcoin wallet system service #
printf "\n"
printf "\nCatcoin node system service... Done.\n"
printf "\n"
cd $current_dir
sudo cp config/catcoind.service /etc/systemd/system/catcoind.service
sudo chown root:root /etc/systemd/system/catcoind.service
sudo systemctl daemon-reload
sudo systemctl enable catcoind
sudo systemctl start catcoind

# Mongodb create database and user #
printf "\n"
printf "\nDb setup... Done.\n"
cd $current_dir
sudo mongosh < config/mongo_init.js

# Explorer node install #
printf "\n"
printf "\nNode modules... Done.\n"
cd /home/explorer/eiquidus
npm install --only=prod

# Catcoin explorer system service #
printf "\n"
printf "\nExplorer system service... Done.\n"
printf "\n"
cd $current_dir
sudo cp config/explorer.service /etc/systemd/system/explorer.service
sudo chown root:root /etc/systemd/system/explorer.service
sudo systemctl daemon-reload
sudo systemctl enable explorer
sudo systemctl start explorer

# Haproxy #
printf "\n"
printf "\nHaproxy setup... Done.\n"
cd $current_dir
sudo cp config/haproxy /etc/haproxy/haproxy.cfg
sudo service haproxy reload

# Ufw rules #
printf "\n"
printf "\nUfw setup... Done.\n"
printf "\n"
printf "\nSelect (y) & press enter.\n"
printf "\n"
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable

# Crons and scripts - explorer blocks, peers, markets & system updates #
printf "\n"
printf "\nCron setup... Done.\n"
cd $current_dir
cp config/blocks.sh /home/explorer/eiquidus/scripts/blocks.sh
cp config/peers.sh /home/explorer/eiquidus/scripts/peers.sh
cp config/markets.sh /home/explorer/eiquidus/scripts/markets.sh
cd /home/explorer/eiquidus/scripts
chmod a+x markets.sh peers.sh blocks.sh
cd $current_dir
sudo cp config/root /var/spool/cron/crontabs/root
sudo chown root:crontab /var/spool/cron/crontabs/root
sudo chmod 600 /var/spool/cron/crontabs/root

printf "\n"
printf "\n** Installation Compete. **\n"
printf "\n"
printf "\n"
