#!/bin/bash

echo "Installer for 'Graph-ETH' on 'Ubuntu 18.04'"

## common variables
script=${BASH_SOURCE[0]}
dir=$(dirname $(readlink -f $0))
source $dir/common_variables.conf

## override / specific variables


if [ $USER != "$prometheus_user" ]; then

	# CHECK root
	if ! [ $(id -u) = 0 ]; then
	   echo "Script must be run as root / sudo."
	   exit 1
	fi
	
	# packages
	apt-get install -y wget tar

	# user account
	adduser --disabled-password --gecos "" $prometheus_user
	HOME=$(getent passwd $prometheus_user | cut -f6 -d:)
	
	# create unitfile
	tee "/etc/systemd/system/$promexp_unit.service" <<EOD
[Unit]
Description=Prometheus node exporter
After=network-online.target

[Service]
User=$prometheus_user
WorkingDirectory=$HOME/node_exporter
ExecStart=$HOME/node_exporter/node_exporter
StandardOutput=journal
StandardError=journal
Restart=always
RestartSec=3
StartLimitInterval=0
LimitNOFILE=65536
LimitNPROC=65536

[Install]
WantedBy=multi-user.target
EOD
	

	# switch user
	echo "loging in as $prometheus_user, now run 'bash $dir/$script' again"
	su $prometheus_user
	exit 0

else

	cd
	
	mkdir node_exporter
	cd node_exporter
	wget $dlurl
	tar -xzf $(basename $dlurl) --strip 1
	
	echo -e "Run 'sudo systemctl start $promexp_unit' & 'sudo systemctl enable $promexp_unit'"
	echo "To see how your indexer is doing, run 'sudo journalctl --follow -o cat -u $promexp_unit' (ctrl+c to stop the logview)."

fi