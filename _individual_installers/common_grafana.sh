#!/bin/bash

# CHECK root
if ! [ $(id -u) = 0 ]; then
   echo "Script must be run as root / sudo."
   exit 1
fi

## common variables
script=${BASH_SOURCE[0]}
dir=$(dirname $(readlink -f $0))
source $dir/common_variables.conf

## override / specific variables


# add repo
apt-get update
apt-get install -y apt-transport-https software-properties-common wget
wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | tee -a /etc/apt/sources.list.d/grafana.list
apt-get update

# install grafana
apt-get install -y grafana

# start grafana
systemctl daemon-reload
systemctl start grafana-server
systemctl enable grafana-server


tee "pg_grafana_rights.sh" <<EOD
#!bin/bash
database_name=$database_name

sudo -u postgres psql -c "CREATE USER grafana WITH PASSWORD 'grafana';"
sudo -u postgres psql -c "GRANT CONNECT ON DATABASE \"\$database_name\" TO grafana;"

sudo -u postgres psql \$database_name -c "GRANT USAGE ON SCHEMA subgraphs TO grafana;"
sudo -u postgres psql \$database_name -c "GRANT SELECT ON ALL TABLES IN SCHEMA subgraphs TO grafana;"

sudo -u postgres psql \$database_name -c "GRANT USAGE ON SCHEMA public TO grafana;"
sudo -u postgres psql \$database_name -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafana;"

sudo -u postgres psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO grafana;"
EOD

echo -e "\n\nCopy and run 'pg_grafana_rights.sh' on the postgres server"

echo -e "Surf to localhost:3000 and login with admin:admin\n"