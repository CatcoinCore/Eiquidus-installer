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
   echo " * Please write down or remember this password & follow on screen prompts. *"
   echo ""
   sleep 10
   adduser explorer
   usermod -aG sudo explorer
   cp -R /root/Eiquidus-installer /home/explorer/Eiquidus-installer
   chown -R explorer:explorer /home/explorer/Eiquidus-installer
   chmod -R 755 /home/explorer/Eiquidus-installer
   echo ""
   echo ""
   echo " * Please write down or take a picture of info below *"
   echo ""
   echo " * Must restart now or install will fail *"
   echo ""
   echo " * Type [reboot] press enter  *"
   echo ""
   echo " * At next startup continue the install *"
   echo ""
   echo " * Login: ssh explorer@server ip *"
   echo ""
   echo " * Start setup: cd Eiquidus-installer && bash install.sh *"
   echo ""
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
printf "\nCatcoin wallet build... Done.\n"

# Catcoin wallet system service #
printf "\n"
printf "\nCatcoin wallet system service install...\n"
printf "\n"
cd $current_dir
sudo cp config/catcoind.service /etc/systemd/system/catcoind.service
sudo chown root:root /etc/systemd/system/catcoind.service
sudo systemctl daemon-reload
sudo systemctl enable catcoind
sudo systemctl start catcoind
printf "\nCatcoin wallet system service... Done.\n"

# Mongodb create database and user #
printf "\n"
printf "\nDb/user install...\n"
cd $current_dir
{
sudo mongosh < config/mongo_init.js
} > /dev/null 2>&1
printf "\nDb/user setup... Done.\n"

# Explorer node modules install #
printf "\n"
printf "\nNode modules install...\n"
cd /home/explorer/eiquidus
npm install --only=prod
printf "\nNode modules... Done.\n"

# Catcoin explorer system service #
printf "\n"
printf "\nExplorer system service install...\n"
printf "\n"
cd $current_dir
sudo cp config/explorer.service /etc/systemd/system/explorer.service
sudo chown root:root /etc/systemd/system/explorer.service
sudo systemctl daemon-reload
sudo systemctl enable explorer
sudo systemctl start explorer
printf "\nExplorer system service... Done.\n"

# Haproxy #
printf "\n"
printf "\nHaproxy install...\n"
cd $current_dir
sudo cp config/haproxy /etc/haproxy/haproxy.cfg
sudo service haproxy reload
printf "\nHaproxy setup... Done.\n"

# Ufw rules #
printf "\n"
printf "\nUfw install...\n"
printf "\n"
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw --force enable
printf "\nUfw setup... Done.\n"

# Crons and scripts - explorer blocks, peers, markets & system updates #
printf "\n"
printf "\nCrons/scripts install...\n"
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
printf "\nCrons/scripts setup... Done.\n"

printf "\n"
printf "\n** Installation Compete. **\n"
printf "\n"
printf "\n"
