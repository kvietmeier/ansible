#!/bin/bash
###=======================================================================================###
#   Setup script for  Grafana and Prometheus - extracted from setup_part1
###=======================================================================================###
#
#   Requirements:
#    	* Ubuntu 18.04 or newer
#		* Root volume >30GB
#	
#	Related/Required scripts/files:
#		* grafana_dashboard_signpost.yaml
#		* prometheus_datasource.yaml
#
#   Modified for Azure by:
#        Karl Vietmeier - Intel Cloud CSA
# 
#   Usage:
#       
###=======================================================================================###

# Make sure we are running in the right dir....
cd "$(dirname "${BASH_SOURCE[0]}")"

### Set parameters


# Need this for .vdbhosts
eth0IP=$(ip -4 -o addr show dev eth0| awk '{split($4,a,"/");print a[1]}')

###====================================== Functions ============================================###
###                                                                                             ###


function setup_grafana () {
	###---- Only run on Grafana on mgmt server!  Don't need on every system.
	###---- Add Grafana Repo and setup dashboards

	# Install Grafana
	wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
	echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
	sudo apt update
	sudo apt-get install -y grafana

	# Configure the Grafana service
	sudo cp grafana_dashboard_signpost.yaml /etc/grafana/provisioning/dashboards
	sudo cp -r ${HOME}/bin/dashboards/* /etc/dashboards
	sudo find /etc/dashboards -exec chgrp grafana {} \;
	sudo cp prometheus_datasource.yaml /etc/grafana/provisioning/datasources
	sudo chgrp grafana /etc/grafana/provisioning/dashboards/grafana_dashboard_signpost.yaml
	sudo chgrp grafana /etc/grafana/provisioning/datasources/prometheus_datasource.yaml
	
	# Start/Enable the service
	sudo /bin/systemctl daemon-reload
	sudo /bin/systemctl enable grafana-server
	sudo /bin/systemctl start grafana-server

	###---- End Grafana
}

function setup_prometheus () {
 
	###---- Set up local prometheus server
	bash prometheusserver_configure.sh

 
	## Disable node_exporter don't need it on mgmt server.
	sudo systemctl stop prometheus-node-exporter
	sudo systemctl disable prometheus-node-exporter
	
	###---- End Prometheus
}


###================================== End Functions ============================================###

###---- Run functions

# These only need to run on mgmt system.
setup_grafana
setup_prometheus


# So we can skip running it again with Ansible
touch $HOME/.setupgfp_ran