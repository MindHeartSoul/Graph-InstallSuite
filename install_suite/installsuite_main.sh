#!/bin/bash

echo "Installer Suite for The Graph on 'Ubuntu 18.04'"

## common variables
script=${BASH_SOURCE[0]}
dir=$(dirname $(readlink -f $0))
individual_installers="$dir/_individual_installers"
source $dir/installsuite_variables.conf

## override / specific variables


## logic
today=$(date +%y%m%d_%H%M)
logfile=installsuite-${today}.log

# CHECK root - not needed for remote
# if ! [ $(id -u) = 0 ]; then
   # echo "Script must be run as root / sudo."
   # exit 1
# fi


## verify correct config or exit
if [ "$install_type" != "mainnet" ] && [ "$install_type" != "testnet" ]; then
	echo "ERROR : unspported install_type" | tee -a $logfile
fi


## prepare arguments according to config values
if [ "$ssh_user" != "root" ]; then
	remote_sudo="sudo"
fi

if ! [ $(id -u) = 0 ]; then
   local_sudo="sudo"
fi

if [ -n "$ssh_keyfile" ]; then
	ssh_keyfile="-i $ssh_keyfile"
fi


## process postgres installation(s)
if [ -n "$servers_postgres" ]; then

	for db in ${servers_postgres[@]}; do
		echo "Installing postgres on $db" | tee -a $logfile
		
		# does the db ip belong to the localhost ?
		db_ip=$(ping -c1 $db | head -n 1 | awk '{print $3}' | sed 's/[)(]//g')
		if [ -n "$(ip addr | grep $db_ip)" ]; then
			$local_sudo $individual_installers/${install_type}_1_postgres.sh
		else
			# needs copying of installer + config ?
			#ssh -p $ssh_port $ssh_keyfile $ssh_user@$db "$remote_sudo $individual_installers/${install_type}_1_postgres.sh"
			ssh -p $ssh_port $ssh_keyfile $ssh_user@$db "$remote_sudo bash -s" < $individual_installers/${install_type}_1_postgres.sh
		fi
	done

else

	echo "Not installing postgres per config." | tee -a $logfile
	
fi