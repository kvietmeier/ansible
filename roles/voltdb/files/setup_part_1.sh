#!/usr/bin/bash
###=======================================================================================###
#   First setup script for creating a VoltDB image 
###=======================================================================================###
#
#   Requirements:
#    	* Ubuntu 18.04 or newer
#		* Root volume >30GB
#		* 2 data volumes >128GB
#		* a $HOME/bin directory with the VoltDB utility scripts and utility packages 
#	
#	Related/Required scripts/files:
#		* filesystem.sh (creates mountpoints on data drives and updated /etc/fstab)
#		* prometheusserver_configure.sh
#		* grafana_dashboard_signpost.yaml
#		* prometheus_datasource.yaml
#		* extra_profile
#
#   Modified for Azure by:
#        Karl Vietmeier - Intel Cloud CSA
# 
#   Usage:
#   	> setup_part_1.sh <voltDB version>
#       
###=======================================================================================###

# Make sure we are running in the right dir....
cd "$(dirname "${BASH_SOURCE[0]}")"

### Set parameters
# Hard coded to versions in the bin directory
# Could I use 11.0.11?
JAVA_BUILD_VERSION=jdk-11.0.4
JAVA_FILE_VERSION=${JAVA_BUILD_VERSION}_linux-x64
VOLT_VERSION=11.4

# Need this for .vdbhosts
eth0IP=$(ip -4 -o addr show dev eth0| awk '{split($4,a,"/");print a[1]}')

# Hardcode for automation
#if [ "$#" != "1" ] ; then
#	echo Usage: $0 voltdb_version
#	exit 1
#fi

export eth0IP Volt_VERSION JAVA_BUILD_VERSION JAVA_FILE_VERSION

# Check Java version
if 
	[ ! -d ${JAVA_BUILD_VERSION} ]
then
	gunzip ${JAVA_FILE_VERSION}_bin.tar.gz
	tar xf ${JAVA_FILE_VERSION}_bin.tar
	gzip ${JAVA_FILE_VERSION}_bin.tar
fi


# Call filesystem.sh
# in Azure the devices have different names
# Why not use checkforssd?  Looks it is the same thing.
sudo bash ./filesystem.sh nvme0n2 /voltdbdatassd1
sudo bash ./filesystem.sh nvme0n3 /voltdbdatassd2

sleep 10 

# Add Grafana Repo
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

sudo apt update
sudo apt-get install -y grafana

# Configure and start Grafana service
sudo cp grafana_dashboard_signpost.yaml /etc/grafana/provisioning/dashboards
sudo cp -r  /home/ubuntu/bin/dashboards/* /etc/dashboards
sudo find /etc/dashboards -exec chgrp grafana {} \;
sudo cp prometheus_datasource.yaml /etc/grafana/provisioning/datasources
sudo chgrp grafana /etc/grafana/provisioning/dashboards/grafana_dashboard_signpost.yaml
sudo chgrp grafana /etc/grafana/provisioning/datasources/prometheus_datasource.yaml
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable grafana-server
sudo /bin/systemctl start grafana-server

# Do this in cloud-init/ansible
#for i in ifstat cloud-utils sysstat curl slurm tcptrack bmon prometheus maven
#do
#	sudo apt install -y $i
#done

# Added this in cloud-init
#sudo sysctl -w vm.overcommit_memory=1

#
# Don't need ntp code in Azure 
#

##
## Disable node_exporter as it's broken.
##
#sudo service prometheus-node-exporter stop
#sudo rm /etc/systemd/system/multi-user.target.wants/prometheus-node-exporter.service
#sudo rm /lib/systemd/system/prometheus-node-exporter.service

# Get VoltDB

# I already grab it and untar/zip it  (KV)
#gunzip voltdb-ent-${VERSION}.tar.gz
#tar xvf voltdb-ent-${VERSION}.tar
#rm voltdb-ent-${VERSION}.tar
#mv voltdb-ent-${VERSION} ..

# create .vdbhosts
###----  Should do this with Ansible
# This is an AWS thing - 
#curl http://169.254.169.254/latest/meta-data/local-ipv4 > $HOME/.vdbhosts

echo $eth0IP >> $HOME/.vdbhosts

# VDB hostnames
echo "localhost" > $HOME/.vdbhostnames

# Record clusterid = 0
echo 0  > $HOME/.voltclusterid

# Add VoltDB and Java to the PATH in .profile
HASVOLT=$(grep voltdb $HOME/.profile)

if [ -z $HASVOLT ] 
then
  cat ${HOME}/bin/extra_profile | sed '1,$s/PARAM_VOLTDB_VERSION/'$1'/g' | sed '1,$s/PARAM_JAVA_VERSION/'${JAVA_BUILD_VERSION}'/g' >> $HOME/.profile
else
  cat ${HOME}/bin/extra_profile | sed '1,$s/PARAM_VOLTDB_VERSION/'${VOLT_VERSION}'/g' | sed '1,$s/PARAM_JAVA_VERSION/'${JAVA_BUILD_VERSION}'/g' >> $HOME/.profile
fi

# Added by KarlV - I like using vi at the CLI
echo "" >> .bashrc
echo "### Added by VoltDB setup" >> .bashrc
echo "set -o vi" >> .bashrc
echo "EDITOR=vi" >> .bashrc

#
# Set up local prometheus
#
sh prometheusserver_configure.sh

##
## set up node_exporter
##
#gunzip node_exporter-1.1.2.linux-amd64.tar.gz
#tar xvf node_exporter-1.1.2.linux-amd64.tar
#gzip  node_exporter-1.1.2.linux-amd64.tar

# Disable THP (really don't need this - it is already done)
sudo bash -c "echo never >/sys/kernel/mm/transparent_hugepage/enabled"
sudo bash -c "echo never >/sys/kernel/mm/transparent_hugepage/defrag"

sudo cp rc.local /etc/rc.local

# services that start enabled
for  i in voltdb voltdbprometheusbl voltdbprometheus voltdb-node-exporter awscfboot prometheus
do
	sudo cp ${i}.service /lib/systemd/system/${i}.service
	sudo systemctl enable ${i}.service
done

# untar kafka
if 
	[ ! -d "kafka_2.13-2.6.0" ]
then
 	tar -xzf kafka_2.13-2.6.0.tgz
	cp kafka_server.properties kafka_2.13-2.6.0/config/server.properties
	#mkdir /voltdbdata/kafka
fi

# services that start disabled
for i in grafana-server 
do
	sudo systemctl disable ${i}.service
done


# Already there from cloud-init
# set up licence
#cp license.xml ${HOME}

# So we can skip running it again with Ansible
touch $HOME/.part1_ran