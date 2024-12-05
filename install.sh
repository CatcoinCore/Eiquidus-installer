#!/usr/bin/env bash
current_dir=$PWD
current_user=$USER
explorer_dir=""
cat_dir=""

# Verify the installer has not been invoked as root user #
if [[ $EUID == 0 ]]; then
   echo ""
   echo " * Do not run this script as root user! *"
   echo ""
   echo " * Creating explorer user.. Please follow on screen prompts.. *"
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
printf "\nSystem update and packages install...\n"
printf "\nBuilding boost plus installing additional packages...\n"
printf "\nThis will take a long time... Minimal output... Please wait patiently...\n"
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
printf "\nBuilding Catcoin... This will take some time...\n"
cd $current_dir/Catcoin-v0.9.3.0/src
{
make -f makefile.unix
} > /dev/null 2>&1
# wallet config #
mkdir ~/.catcoin
cd $current_dir
cp config/catcoin ~/.catcoin/catcoin.conf
# Start Catcoin wallet #
cd $current_dir/Catcoin-v0.9.3.0/src
cat_dir=$PWD
./catcoind

# Mongodb cli create database and user #
printf "\n"
printf "\nDb setup... Done.\n"
cd $current_dir
sudo mongosh < config/mongo_init.js

# Haproxy #
printf "\n"
printf "\nHaproxy setup... Done.\n"
cd $current_dir
sudo cp config/haproxy /etc/haproxy/haproxy.cfg
sudo service haproxy reload

# Explorer process start #
printf "\n"
printf "\nScreen setup... Done.\n"
cd $current_dir
cd /home/explorer/eiquidus
screen -dmS explorer bash -c "bash  /home/explorer/Eiquidus-installer/config/screen.sh"

# Crons and scripts - updates blocks, peers & markets #
printf "\n"
printf "\nCron setup... Done.\n"
cd $current_dir
cp config/blocks.sh /home/explorer/eiquidus/scripts/blocks.sh
cp config/peers.sh /home/explorer/eiquidus/scripts/peers.sh
cp config/markets.sh /home/explorer/eiquidus/scripts/markets.sh
(crontab -l 2>/dev/null; echo "*/1 * * * * cd /home/explorer/eiquidus/scripts && ./blocks.sh > /dev/null 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/5 * * * * cd /home/explorer/eiquidus/scripts && ./peers.sh > /dev/null 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/10 * * * * cd /home/explorer/eiquidus/scripts && ./markets.sh > /dev/null 2>&1") | crontab -

printf "\n"
printf "\n** Installation Compete. **\n"
printf "\n"
printf "\n"
