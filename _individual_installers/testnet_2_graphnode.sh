#!/bin/bash

echo "Installer for 'testnet graph-node' on 'Ubuntu 20.04'"

## common variables
script=${BASH_SOURCE[0]}
dir=$(dirname $(readlink -f $0))
source $dir/testnet_variables.conf

## override / specific variables


# adjustments
for i in "$@"; do

	if [ "$i" == "query" ] || [ "$i" == "querynode" ]; then
		_query="1"
		
		break
	fi
	
	if [ "$i" == "indexer" ] || [ "$i" == "indexernode" ]; then
		_indexer="1"
		
		break
	fi
	
	if [ "$i" == "both" ]; then
		_query="1"
		_indexer="1"
		
		break
	fi

done

if [ "$_query" != 1 ] && [ "$_indexer" != 1 ]; then
	echo "Setting node config as default : both"
	
	_query="1"
	_indexer="1"
fi


## logic
if [ $USER != "$graphnode_user" ]; then
	# CHECK root
	if ! [ $(id -u) = 0 ]; then
	   echo "Script must be run as root / sudo."
	   exit 1
	fi
	
	# packages
	apt-get install -y curl git build-essential pkg-config libssl-dev libpq-dev cmake

	# user account
	adduser --disabled-password --gecos "" $graphnode_user
	HOME=$(getent passwd $graphnode_user | cut -f6 -d:)
	
	# create unitfiles
	
	if [ "$_query" == 1 ]; then
	tee "/etc/systemd/system/$query_unit.service" <<EOD
[Unit]
Description=$query_unit
After=network-online.target

[Service]
User=$graphnode_user
WorkingDirectory=$HOME
ExecStart=$HOME/$query_unit.sh
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
	fi
	
	if [ "$_indexer" == 1 ]; then
	tee "/etc/systemd/system/$indexer_unit.service" <<EOD
[Unit]
Description=$indexer_unit
After=network-online.target

[Service]
User=$graphnode_user
WorkingDirectory=$HOME
ExecStart=$HOME/$indexer_unit.sh
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
	fi
		
	# switch user
	echo "loging in as $graphnode_user, now run 'bash $dir/$script' again"
	su $graphnode_user
	exit 0

else

	cd $HOME
	
	echo "Don't forget to update permissions in postgres server (firewall & pg_hba.conf)"
	
	if [ "$_query" == 1 ]; then
	cat <<EOD > "$HOME/$query_unit.sh"
#!/bin/bash
eth_mainnet_archive=$eth_mainnet_archive

export GRAPH_LOG_QUERY_TIMING="gql"
export DISABLE_BLOCK_INGESTOR="true"

source \$HOME/.cargo/env
cd \$HOME/graph-node
cargo run -p graph-node --release -- \\
  --http-port $graphnode_query_8000 \\
  --admin-port $graphnode_query_8020 \\
  --index-node-port $graphnode_query_8030 \\
  --metrics-port $graphnode_query_8040 \\
  --ws-port $graphnode_query_8001 \\
  --postgres-url postgresql://$database_user:$database_pwd@$database_url:$database_port/$database_name \\
  --ethereum-rpc mainnet:\$eth_mainnet_archive \\
  --ipfs $ipfs \\
  --node-id $query_id
EOD

chmod +x $HOME/$query_unit.sh

	fi
	
	if [ "$_indexer" == 1 ]; then
	cat <<EOD > "$HOME/$indexer_unit.sh"
#!/bin/bash
eth_mainnet_archive=$eth_mainnet_archive

source \$HOME/.cargo/env
cd \$HOME/graph-node
cargo run -p graph-node --release -- \\
  --http-port $graphnode_indexer_8000 \\
  --admin-port $graphnode_indexer_8020 \\
  --index-node-port $graphnode_indexer_8030 \\
  --metrics-port $graphnode_indexer_8040 \\
  --ws-port $graphnode_indexer_8001 \\
  --postgres-url postgresql://$database_user:$database_pwd@$database_url:$database_port/$database_name \\
  --ethereum-rpc mainnet:$eth_mainnet_archive \\
  --ipfs $ipfs \\
  --node-id $indexer_id
EOD

chmod +x $HOME/$indexer_unit.sh

	fi

	# install rustup
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
	
	# rustup settings
	source ~/.cargo/env
	rustup default stable
	
	# get graph-node
	if [ -d "graph-node" ]; then
		cd graph-node
		git checkout master
		git pull
	else 
		git clone https://github.com/graphprotocol/graph-node
		cd graph-node
	fi
	
	# compile graph-node
	git checkout $graphnode_buildid
	cargo build --release
	
	# finish info
	if [ "$_indexer" == 1 ]; then
		echo -e "Run 'sudo systemctl start $indexer_unit' & 'sudo systemctl enable $indexer_unit' to start your indexer"
		echo "To see how your indexer is doing, run 'sudo journalctl --follow -o cat -u $indexer_unit' (ctrl+c to stop the logview)."
	fi
	
	if [ "$_query" == 1 ]; then
		echo -e "Run 'sudo systemctl start $query_unit' & 'sudo systemctl enable $query_unit' to start your querynode"
		echo "To see how your querynode is doing, run 'sudo journalctl --follow -o cat -u $query_unit' (ctrl+c to stop the logview)."
	fi
fi