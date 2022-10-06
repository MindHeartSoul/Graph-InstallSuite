#!/bin/bash

echo "Installer for 'Prometheus' on 'Ubuntu 20.04'"

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
	apt-get install -y wget tar curl

	# user account
	adduser --disabled-password --gecos "" $prometheus_user
	
	# create unitfile
	tee "/etc/systemd/system/$prometheus_unit.service" <<EOD
[Unit]
Description=Prometheus monitoring
After=network-online.target

[Service]
User=$prometheus_user
WorkingDirectory=/home/$prometheus_user/prometheus
ExecStart=/home/$prometheus_user/prometheus/prometheus --config.file=/home/$prometheus_user/prometheus/config/prometheus.yml
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

	mkdir prometheus
	cd prometheus
	wget $prometheus_dl_url
	tar -xzf prometheus* --strip 1
	
	mkdir config

	tee "config/prometheus.yml" <<EOD
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'graph-monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label  to any timeseries scraped from this config.
#  - job_name: 'prometheus'

    # Override the global default and scrape targets from this job every 5 seconds.
#    scrape_interval: 5s

#    static_configs:
#      - targets: ['localhost:9090']


# The Graph
  - job_name:       'indexers'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s

#    scheme: https

    static_configs:
      - targets: [ $prom_indexers ]
        labels:
          group: $prom_group


  - job_name:       'query'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s

#    scheme: https

    static_configs:
      - targets: [ $prom_querynodes ]
        labels:
          group: $prom_group


  - job_name:       'service'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s

#    scheme: https
#    metrics_path: /

    static_configs:
      - targets: [ $prom_services ]
        labels:
          group: $prom_group


  - job_name:       'agent'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s

#    scheme: https
#    metrics_path: /

    static_configs:
      - targets: [ $prom_agent ]
        labels:
          group: $prom_group
EOD

	echo -e "Run 'sudo systemctl start $prometheus_unit' & 'sudo systemctl enable $prometheus_unit'"
	echo "To see how your indexer is doing, run 'sudo journalctl --follow -o cat -u $prometheus_unit' (ctrl+c to stop the logview)."

fi