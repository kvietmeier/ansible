#!/usr/bin/bash
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
#       * prometheusserver_configure.sh
#
#   Modified for Azure by:
#        Karl Vietmeier - Intel Cloud CSA
# 
#   Usage:
#       
###=======================================================================================###

# Make sure we are running in the right dir....
cd "$(dirname "${BASH_SOURCE[0]}")"

###--- Vars
src_dashboard_dir=${HOME}/bin/dashboards
tgt_dashboard_dir=/etc/grafana/provisioning/dashboards
tgt_data_dir=/etc/grafana/provisioning/datasources
PASSWORD="n0mad1c"

# Need these for .vdbhosts and .clusterid
eth0IP=$(ip -4 -o addr show dev eth0| awk '{split($4,a,"/");print a[1]}')
clusterid="0"



###====================================== Functions ============================================###
###                                                                                             ###


function setup_grafana () {
	###---- Only run on Grafana on mgmt server!  Don't need on every system.
	###---- Add Grafana Repo and setup dashboards

	echo ""
	echo "Installing Grafana"   
	echo ""

	# Need for config - 
	echo $eth0IP > $HOME/.vdbhosts
	echo $clusterid > $HOME/.voltclusterid
    
	# Install Grafana
	wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
	echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
	sudo apt update
	sudo apt-get install -y grafana

	# Configure the Grafana service
	sudo cp grafana_dashboard_signpost.yaml $tgt_dashboard_dir
	sudo cp -r ${src_dashboard_dir}/* $tgt_dashboard_dir
	sudo find $tgt_dashboard_dir -exec chgrp grafana {} \;
	sudo cp prometheus_datasource.yaml $tgt_data_dir
	sudo chgrp grafana ${tgt_dashboard_dir}/grafana_dashboard_signpost.yaml
	sudo chgrp grafana ${tgt_data_dir}/prometheus_datasource.yaml
	
	# Seems to be a permissions issue
	sudo chown -R grafana:grafana /var/lib/grafana/

	# Start/Enable the service
	sudo /bin/systemctl daemon-reload
	sudo /bin/systemctl enable grafana-server
	sudo /bin/systemctl start grafana-server

	sudo grafana-cli admin reset-admin-password $PASSWORD
	
	###---- End Grafana
}

function setup_prometheus () {
 
	echo ""
	echo "Installing Prometheus"   
	echo ""
	
	###---- Set up local prometheus server
	bash prometheusserver_configure.sh

	## Disable node_exporter don't need it on mgmt server.
	sudo systemctl is-active --quiet prometheus-node-exporter

	if  [ "$?" = "0" ] ; then
  	    echo stopping node-exporter ...
	  	sudo systemctl stop prometheus-node-exporter
	else
		echo "node-exporter not running, nothing to do"
	fi
	
	# Make sure it doesn't start
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