#!/bin/bash

echo "Installer for 'testnet agent' on 'Ubuntu 18.04'"

## common variables
script=${BASH_SOURCE[0]}
dir=$(dirname $(readlink -f $0))
source $dir/testnet_variables.conf

## override / specific variables


# logic
if [ $USER != "$agent_user" ]; then
	# CHECK root
	if ! [ $(id -u) = 0 ]; then
	   echo "Script must be run as root / sudo."
	   exit 1
	fi
	
	# user account
	adduser --disabled-password --gecos "" $agent_user
	HOME=$(getent passwd $agent_user | cut -f6 -d:)

	# install packages
	apt-get install -y wget curl libsecret-1-dev build-essential clang
	
	# create unitfile
	cat <<EOD > "/etc/systemd/system/$agent_unit.service"
[Unit]
Description=$agent_unit
After=network-online.target

[Service]
User=$agent_user
WorkingDirectory=$HOME
ExecStart=$HOME/$agent_unit.sh
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
	echo "loging in as $agent_user, now run 'bash $dir/$script' again"
	su $agent_user
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
	npm install -g @graphprotocol/indexer-agent@$wrappers_buildid @graphprotocol/graph-pino
	
	# create runfile
	cat <<EOD > "$HOME/$agent_unit.sh"
#!/bin/bash
ops_mnemonic="$ops_mnemonic"
admin_address="$admin_address"
rpc_contracts="$rpc_contracts"

database_pwd="$database_pwd"
database_access="$database_access"
database_url="$database_url"

network_subgraph="$network_subgraph"
con_service="$con_service"
con_query="$con_query"
indexer_ids="$indexer_id"

allocation_threshold=$allocation_threshold
receipts_endpoint=$receipts_endpoint

export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"

graph-indexer-agent start \\
    --graph-node-query-endpoint \$con_query:$graphnode_query_8000/ \\
    --graph-node-admin-endpoint \$con_query:$graphnode_query_8020/ \\
    --graph-node-status-endpoint \$con_query:$graphnode_query_8030/graphql \\
    --index-node-ids "\$indexer_ids" \\
    --public-indexer-url \$con_service/ \\
    --metrics-port $agent_metrics \\
    --indexer-management-port $agent_management \\
    --indexer-geo-coordinates "$geo" \\
    --postgres-host \$database_url \\
    --postgres-port $database_port \\
    --postgres-database \$database_access \\
    --postgres-username $database_user \\
    --postgres-password \$database_pwd \\
    --network-subgraph-endpoint \$network_subgraph \\
	--ethereum-network rinkeby \\
    --ethereum \$rpc_contracts \\
    --mnemonic "\$ops_mnemonic" \\
    --indexer-address \$admin_address \\
	--allocation-claim-threshold \$allocation_threshold \\
	--collect-receipts-endpoint \$receipts_endpoint
EOD

chmod +x $HOME/$agent_unit.sh

	# finish info
	if [ "$_indexer" == 1 ]; then
	echo -e "Run 'sudo systemctl start $agent_unit' & 'sudo systemctl enable $agent_unit' to start your indexer"
	echo "To see how your indexer is doing, run 'sudo journalctl --follow -o cat -u $agent_unit' (ctrl+c to stop the logview)."
	fi
	
fi
