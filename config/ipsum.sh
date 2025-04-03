	## Pre install: sudo apt -qq install iptables ipset ##
	#!/bin/bash -l
sudo ipset -q flush ipsum
sudo ipset -q create ipsum hash:ip
for ip in $(curl --compressed https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt 2>/dev/null | grep -v "#" | grep -v -E "\s[1-2]$" | cut -f 1); do ipset add ipsum $ip; done
sudo iptables -D INPUT -m set --match-set ipsum src -j DROP 2>/dev/null
sudo iptables -I INPUT -m set --match-set ipsum src -j DROP
