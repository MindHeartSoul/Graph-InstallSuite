#!/bin/bash

echo "Installer for 'mainnet service' on 'Ubuntu 18.04'"

## common variables
script=${BASH_SOURCE[0]}
dir=$(dirname $(readlink -f $0))
source $dir/mainnet_variables.conf

## override / specific variables



# logic
if [ $USER != "$service_user" ]; then
	# CHECK root
	if ! [ $(id -u) = 0 ]; then
	   echo "Script must be run as root / sudo."
	   exit 1
	fi
	
	# user account
	adduser --disabled-password --gecos "" $service_user
	#HOME=$(eval echo "~$service_user")
	HOME=$(getent passwd $service_user | cut -f6 -d:)

	# install packages
	apt-get install -y wget curl libsecret-1-dev
	
	# create unitfile
	cat <<EOD > "/etc/systemd/system/$service_unit.service"
[Unit]
Description=$service_unit
After=network-online.target

[Service]
User=$service_user
WorkingDirectory=$HOME
ExecStart=$HOME/$service_unit.sh
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
	echo "loging in as $service_user, now run 'bash $dir/$script' again"
	su $service_user
	exit 0

else 

	cd $HOME
	
	echo "Don't forget to update permissions in postgres server (firewall & pg_hba.conf)"
	
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
	npm install -g nan
	npm install -g @graphprotocol/indexer-service@$wrappers_buildid @graphprotocol/graph-pino
	
	# create runfile
	cat <<EOD > "$HOME/$service_unit.sh"
#!/bin/bash

# variables
ops_mnemonic="$ops_mnemonic"
admin_address="$admin_address"
rpc_contracts="$rpc_contracts"

database_pwd="$database_pwd"
database_access="$database_access"
database_url="$database_url"

network_subgraph="$network_subgraph"
con_service="$con_service"
con_query="$con_query"

client_signer=$client_signer

export SKIP_EVM_VALIDATION=true
export INDEXER_SERVICE_WALLET_WORKER_THREADS=12

export SERVER_HOST=\$database_url
export SERVER_PORT=$database_port
export SERVER_DB_NAME=\$database_access
export SERVER_DB_USER=$database_user
export SERVER_DB_PASSWORD=\$database_pwd

export INDEXER_SERVICE_POSTGRES_HOST=\$SERVER_HOST
export INDEXER_SERVICE_POSTGRES_PORT=\$SERVER_PORT
export INDEXER_SERVICE_POSTGRES_DATABASE=\$SERVER_DB_NAME
export INDEXER_SERVICE_POSTGRES_USERNAME=\$SERVER_DB_USER
export INDEXER_SERVICE_POSTGRES_PASSWORD=\$SERVER_DB_PASSWORD

export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"

graph-indexer-service start \\
    --port $service_query \\
    --graph-node-query-endpoint \$con_query:$graphnode_query_8000/ \\
    --graph-node-status-endpoint \$con_query:$graphnode_query_8030/graphql \\
	--metrics-port $service_metrics \\
    --network-subgraph-endpoint \$network_subgraph \\
	--ethereum-network mainnet \\
    --ethereum \$rpc_contracts \\
    --mnemonic "\$ops_mnemonic" \\
    --indexer-address \$admin_address \\
	--client-signer-address $client_signer

EOD

chmod +x $HOME/$service_unit.sh
	
	# finish info
	if [ "$_indexer" == 1 ]; then
	echo -e "Run 'sudo systemctl start $service_unit' & 'sudo systemctl enable $service_unit' to start your indexer"
	echo "To see how your indexer is doing, run 'sudo journalctl --follow -o cat -u $service_unit' (ctrl+c to stop the logview)."
	fi

fi
