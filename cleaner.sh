### Run this if install fails, hangs/freezes for an hour or more ###
#!/usr/bin/env bash
cd ~/
rm -rf .catcoin
rm -rf eiquidus
cd /home/explorer/Eiquidus-installer
rm -rf Catcoin-v0.9.3.0
rm install.log
sudo reboot
exit 0
