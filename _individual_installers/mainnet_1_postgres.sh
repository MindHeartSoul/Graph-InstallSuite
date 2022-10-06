#!/bin/bash

echo "Installer for 'mainnet postgres' on 'Ubuntu 18.04'"

# db pasword write hardcode file

## common variables
script=${BASH_SOURCE[0]}
dir=$(dirname $(readlink -f $0))
source $dir/mainnet_variables.conf

## override / specific variables


## logic
# CHECK root
if ! [ $(id -u) = 0 ]; then
   echo "Script must be run as root / sudo."
   exit 1
fi

# install postgres
apt-get update
apt-get install -y wget sudo
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update
apt-get install -y postgresql-12

# prepare postgres
if [ -z "$database_pwd" ]; then
	#read -p "Enter password for postgres : " database_pwd
	database_pwd=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 44 ; echo '')
	echo -e "\ndatabase_pwd=$database_pwd" >> $dir/mainnet_variables.conf
fi 

sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$database_pwd';"
sudo -u postgres createdb $database_name
sudo -u postgres createdb $database_access

echo -e "If you want to access this postgres remotely edit :\n * /etc/postgresql/12/main/postgresql.conf with the appropriate listen_addresses\n * /etc/postgresql/12/main/pg_hba.conf with the corresponding host entries."