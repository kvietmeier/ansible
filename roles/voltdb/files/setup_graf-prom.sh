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
#
#   Modified for Azure by:
#        Karl Vietmeier - Intel Cloud CSA
#
#        Merged in prometheusserver_configure.sh and used a more standardsetup.
#        https://devopscube.com/install-configure-prometheus-linux/
#
###=======================================================================================###

# Make sure we are running in the right dir....
cd "$(dirname "${BASH_SOURCE[0]}")"

###--- Vars
# Need these for .vdbhosts and .clusterid
eth0IP=$(ip -4 -o addr show dev eth0| awk '{split($4,a,"/");print a[1]}')
clusterid="0"

# Files/hosts etc.
MYCLUSTERID=$(cat ${HOME}/.voltclusterid)
VOLTHOSTS=$(cat ${HOME}/.vdbhostnames)
HOSTS=$(tr '\n' ',' < ${HOME}/.vdbhostnames | sed 's/,$//')
LOGDIR=${HOME}/logs

# Grafana - 
src_dashboard_dir=${HOME}/bin/dashboards
tgt_dashboard_dir=/etc/grafana/provisioning/dashboards
tgt_data_dir=/etc/grafana/provisioning/datasources
PASSWORD="n0mad1c"

# Prometheus -
PromVer="2.36.1"
PromTar="prometheus-${PromVer}.linux-amd64.tar.gz"
PromDir="prometheus-${PromVer}.linux-amd64"
PromTempDir="prometheus-files"
PromLink="https://github.com/prometheus/prometheus/releases/download/v${PromVer}/prometheus-${PromVer}.linux-amd64.tar.gz"

# Ports - 
#   9100: Default node_exporter
#   9101: Customized VoltDB NE
#   9102: Database Stats exporter
target_ports=(9100 9101 9102)    # Create an array of target ports
PROMSERVER_PORT=9090


###--- End vars

###====================================== Functions ============================================###
###         

# Check if a user exists - 
# usage:  if ! user_exists username; then....
user_exists() { 
	id -u $1 > /dev/null 2>&1
}                                                                                    ###

function setup_grafana () {
	###---- Only run on Grafana on mgmt server!  Don't need on every system.
	###---- Add Grafana Repo and setup dashboards

	echo ""
	echo "Installing Grafana"   
	echo ""

	# Need for config - 
	echo $eth0IP > $HOME/.vdbhosts
	echo $clusterid > $HOME/.voltclusterid
    
	# Download ame install Grafana
	wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
	echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
	sudo apt update
	sudo apt-get install -y grafana

	# Configure the Grafana service
	sudo cp grafana_dashboard_signpost.yaml $tgt_dashboard_dir
	sudo cp -r ${src_dashboard_dir}/* $tgt_dashboard_dir
	sudo find $tgt_dashboard_dir -exec chgrp grafana {} \;
	sudo cp prometheus_datasource.yaml $tgt_data_dir
	
	# Seems to be a permissions issue
	sudo chgrp grafana ${tgt_dashboard_dir}/grafana_dashboard_signpost.yaml
	sudo chgrp grafana ${tgt_data_dir}/prometheus_datasource.yaml
	sudo chown -R grafana:grafana /var/lib/grafana/

	# Start/Enable the service
	sudo systemctl daemon-reload
	for i in enable start ; do
	  date | tee -a $LOGFILE
	  sudo systemctl ${i} grafana-server  | tee -a $LOGFILE
	done

	sudo grafana-cli admin reset-admin-password $PASSWORD
	
	###---- End Grafana
}

function setup_prometheus () {
	###=======================================================================================###
	#      Setup Prometheus
	###=======================================================================================###

	echo ""
	echo "Installing and Configuring Prometheus"   
	echo ""
	

	### Steps to manually install a specific version
	# First get rid of the package if we have it
	if [ -f $PromTar ] ; then
	  rm $PromTar 2> /dev/null
	fi

	# Grab a new tarball, untar/compress amd move (not sure why we do this)
	wget $PromLink
	tar xzf $PromTar
	mv $PromDir prometheus-files

	# Create a Prometheus user, required directories, 
	# and make Prometheus the user as the owner of those directories.

	# Does prometheus user exist if not - create it?
	user_exists prometheus
	if [ $? -eq 1 ] ; then
		sudo useradd --no-create-home --shell /bin/false prometheus
	fi

	###---- Logging directory for output
	if [ ! -d /etc/prometheus ] ; then
  		sudo mkdir /etc/prometheus 2> /dev/null
	fi
	if [ ! -d /var/lib/prometheus ] ; then
  		sudo mkdir /var/lib/prometheus 2> /dev/null
	fi
	#sudo mkdir /etc/prometheus
	#sudo mkdir /var/lib/prometheus
	sudo chown prometheus:prometheus /etc/prometheus
	sudo chown prometheus:prometheus /var/lib/prometheus

    # Copy prometheus and promtool binary to /usr/local/bin and change the 
	# ownership to prometheus user.
	sudo cp ./prometheus-files/prometheus /usr/local/bin/
	sudo cp ./prometheus-files/promtool /usr/local/bin/
	sudo chown prometheus:prometheus /usr/local/bin/prometheus
	sudo chown prometheus:prometheus /usr/local/bin/promtool

    # Move the consoles and console_libraries directories from prometheus-files to 
	# /etc/prometheus folder and change the ownership to prometheus user.
	sudo cp -r ./prometheus-files/consoles /etc/prometheus
	sudo cp -r ./prometheus-files/console_libraries /etc/prometheus
	sudo chown -R prometheus:prometheus /etc/prometheus/consoles
	sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries

	# Clean up
	rm $PromBin 2> /dev/null

	# Setup the prometheus.xml file

	# Are we a single node?
	if [ "$VOLTHOSTS" = "localhost" ] ; then
	  cat prometheus.yml.template | sed '1,$s/VOLTDB_CLUSTER_NAME/Site'${MYCLUSTERID}'/g' > prometheus.yml

	# No - then setup the DB nodes
	else
	  cat prometheus.yml.template | sed '1,$s/VOLTDB_CLUSTER_NAME/Site'${MYCLUSTERID}'/g'  | grep -v localhost > prometheus.yml
	  echo -n "             - targets: [" >> prometheus.yml

	  COMMA=

		for host in `echo $VOLTHOSTS | sed '1,$s/,/ /g'` ; do
 			for port in "${target_ports[@]}" ; do
  		        echo -n "${COMMA}'${host}:${port}'" >> prometheus.yml
				COMMA=","
    		done
		done
  
  		echo  ",'localhost:9100']" >> prometheus.yml

	fi

	# Copy config and unit files
	sudo cp ./prometheus.yml /etc/prometheus/prometheus.yml
	sudo cp ./prometheus.service /etc/systemd/system/

	# Set permissions - 
	sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml
	sudo chown -R prometheus:prometheus /var/lib/prometheus/

	# Restart everything
	sudo systemctl daemon-reload
	for i in enable start ; do
	  sudo systemctl ${i} prometheus.service
	done


	###---- Set up local prometheus server
	#bash prometheusserver_configure.sh

	
	
	###---- End Prometheus
}


function disable_node_exporter () {
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

}


###================================== End Functions ============================================###

###---- Run functions
# These only need to run on mgmt system.
disable_node_exporter
setup_grafana
setup_prometheus


# So we can skip running it again with Ansible
touch $HOME/.setupgfp_ran