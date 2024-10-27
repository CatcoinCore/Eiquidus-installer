#!/usr/bin/env bash
cd ~/
ubuntu_version=""

# Verify script has been invoked as root user #
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi
# Check Ubuntu version #
if [[ $(lsb_release -rs) == "24.04" ]]; then
       echo "Compatible version. Proceeding."
       ubuntu_version=$(lsb_release -rs)
elif [[ $(lsb_release -rs) == "22.04" ]]; then
       echo "Compatible version. Proceeding."
       ubuntu_version=$(lsb_release -rs)
elif [[ $(lsb_release -rs) == "20.04" ]]; then
       echo "Compatible version. Proceeding."
       ubuntu_version=$(lsb_release -rs)
else
       echo "Non-compatible version of Ubuntu. Exiting..."
       exit 1
fi

# Swap file #
printf "\n"
printf "\nAdding swap file...\n"
sleep 2
sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && sudo echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

# System packages #
printf "\n"
printf "\nInstalling additional system build packages...\n"
sleep 2
{
sudo apt-get -y install make curl git libdb++-dev dirmngr gnupg apt-transport-https ca-certificates zlib1g-dev build-essential haproxy ntpdate
} > /dev/null 2>&1

# Time servers #
printf "\n"
printf "\nAdding time servers...\n"
sleep 2
sudo ntpdate 0.pool.ntp.org
sudo ntpdate 1.pool.ntp.org

# Additional wallet build packages #
# Catcoin 0.9.3.0 specific packages - can be remove when updated wallet is released #
printf "\n"
printf "\nInstalling Catcoin 0.9.3.0 specific build packages...\n"
sleep 2
{
wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb && wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0-dev_1.0.2n-1ubuntu5.13_amd64.deb && wget http://security.ubuntu.com/ubuntu/pool/main/b/boost1.65.1/boost1.65.1_1.65.1+dfsg.orig.tar.bz2 && wget http://security.ubuntu.com/ubuntu/pool/main/m/miniupnpc/libminiupnpc10_1.9.20140610-4ubuntu2_amd64.deb && wget http://security.ubuntu.com/ubuntu/pool/main/m/miniupnpc/libminiupnpc-dev_1.9.20140610-4ubuntu2_amd64.deb
sudo dpkg -i libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb && sudo dpkg -i libssl1.0-dev_1.0.2n-1ubuntu5.13_amd64.deb && sudo dpkg -i libminiupnpc10_1.9.20140610-4ubuntu2_amd64.deb && sudo dpkg -i libminiupnpc-dev_1.9.20140610-4ubuntu2_amd64.deb
tar xvf boost1.65.1_1.65.1+dfsg.orig.tar.bz2 && cd boost_1_65_1 && ./bootstrap.sh && sudo ./b2 install && sudo ldconfig
} > /dev/null 2>&1

# gcc 10 for u22/24 compatibility #
printf "\n"
printf "\nInstalling gcc-10...\n"
sleep 2
{
sudo apt-get -y install g++-10
} > /dev/null 2>&1
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 10 && sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 10

# Catcoin 0.9.3.0 specific - can be removed when updated wallet is released #
sudo apt-mark hold libminiupnpc-dev

printf "\n"
printf "\nSystem and packages successfully updated...\n"
sleep 2

# Nodejs install #
printf "\n"
printf "\nInstalling nodejs...\n"
sleep 2
curl -sL https://deb.nodesource.com/setup_22.x | sudo -E bash -
{
sudo apt-get -y install nodejs
} > /dev/null 2>&1

# Mongodb install #
printf "\n"
printf "\nInstalling mongodb...\n"
sleep 2
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
--dearmor
if [ "$ubuntu_version" == "24.04" ]; then
  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
elif [ "$ubuntu_version" == "22.04" ]; then
  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
elif [ "$ubuntu_version" == "20.04" ]; then
  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
else
  echo "This version of Linux is not compatible with the installer's dependencies. Exiting..."
  exit 1
fi

{
sudo apt-get update
} > /dev/null 2>&1
{
sudo apt-get -y install mongodb-org
} > /dev/null 2>&1

# Static mongodb version 8 #
sudo apt-mark hold mongodb-org
sudo apt-mark hold mongodb-org-database
sudo apt-mark hold mongodb-org-server
sudo apt-mark hold mongodb-mongosh
sudo apt-mark hold mongodb-org-mongos
sudo apt-mark hold mongodb-org-tools

# Mongodb startup #
echo "Enabling MongoDB at startup..."
sleep 2
sudo systemctl enable mongod.service
sudo systemctl start mongod.service

exit 0
