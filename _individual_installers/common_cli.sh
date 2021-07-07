#!/bin/bash

echo "Installer for 'Graph Agent & Service' on 'Ubuntu 18.04'"

## common variables
script=${BASH_SOURCE[0]}
dir=$(dirname $(readlink -f $0))
source $dir/common_variables.conf

## override / specific variables


if [ $USER != "$cli_user" ]; then
	# CHECK root
	if ! [ $(id -u) = 0 ]; then
	   echo "Script must be run as root / sudo."
	   exit 1
	fi
	
	# packages
	apt-get install -y  libsecret-1-dev build-essential
	
	# user account
	adduser --disabled-password --gecos "" $cli_user

	# switch user
	echo "login as $cli_user by running 'su $cli_user' and start script again"
	su $cli_user
	exit 0

else

	# install npm 
	wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_version/install.sh | bash
	source $HOME/.bashrc
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
	nvm install --lts
	
	# verify nodeJS / NPM install
	node -v
	npm -v
	
	# install rustup
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
	
	# rustup settings
	source ~/.cargo/env
	rustup default stable
	
	#verify caro / rustc install
	cargo -V
	rustc -V
	
	# graph npm packages
	npm install -g @graphprotocol/indexer-cli

	graph indexer connect $con_agent
	graph indexer status

fi
