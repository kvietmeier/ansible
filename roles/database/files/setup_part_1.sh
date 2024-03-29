#!/bin/bash
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
#		* extra_profile
#		* voltdb.service
#		* Prometheus setup:
#          -  prometheus.service
#          -  prometheus.yml
#          -  prometheus_start.sh
#          -  prometheus_stop.sh
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
JAVA_BUILD_VERSION="jdk-11.0.11"
JAVA_FILE_VERSION=${JAVA_BUILD_VERSION}_linux-x64
VOLT_VERSION="11.4"
Kafka_Ver="2.13-2.6.0"

###--- Data disk information
#  Are we using Azure nvme controller or regular sd controller?
#  SCSI - sd_drives will always have one drive in it
#         / isn't always on sda but LUNs for data disks start at 11
#         If not using NVME, nvme_drives wil be empty
#  NVME - You will still have sda for the ephemeral /tmp disk
#         LUNS for data disks start at 1 an3ile

nvme_drives=($(ls -l /dev/disk/by-path | grep nvme | grep -v part | awk '{print substr($11, 7)}' | sort))
sd_drives=($(ls -l /dev/disk/by-path | grep sd | egrep "lun-11|lun-12" | awk '{print $11}' | awk -F '/' '{print $3}' | sort))
data_mnt="/voltdbdatassd"
disk_num=1

# Need this for .vdbhosts
eth0IP=$(ip -4 -o addr show dev eth0| awk '{split($4,a,"/");print a[1]}')

export disk_num eth0IP Volt_VERSION JAVA_BUILD_VERSION JAVA_FILE_VERSION Kafka_Ver data_mnt

###---- Check Java version
if 
	[ ! -d ${JAVA_BUILD_VERSION} ]
then
	tar xzf ${JAVA_FILE_VERSION}_bin.tar.gz
fi


###====================================== Functions ============================================###
###                                                                                             ###

function setup_env () {
	###---- Setup local user environment
	
	echo $eth0IP >> $HOME/.vdbhosts

	# VDB hostnames - localhost as default
	echo "localhost" > $HOME/.vdbhostnames

	# Record default clusterid = 0
	echo 0  > $HOME/.voltclusterid

	# Add VoltDB and Java to the PATH in .profile
	HASVOLT=$(grep voltdb $HOME/.profile)
	if [ -z "$HASVOLT" ] ; then
      cat ${HOME}/bin/extra_profile | sed '1,$s/PARAM_VOLTDB_VERSION/'${VOLT_VERSION}'/g' | sed '1,$s/PARAM_JAVA_VERSION/'${JAVA_BUILD_VERSION}'/g' >> $HOME/.profile
    fi

	###---- End Environment
}

function setup_system () {
    ###---- Setup system tuning and apps
    
	# Why?  No need to rerun checkforssd.sh every time - after first time they are in/etc/fstab
	# And we are using systemd anyway.
	#sudo cp rc.local /etc/rc.local
	
	# Disable THP (really don't need this - it is already done)
	sudo bash -c "echo never >/sys/kernel/mm/transparent_hugepage/enabled"
	sudo bash -c "echo never >/sys/kernel/mm/transparent_hugepage/defrag"

	# Copy unit files for services that start enabled
	#for  i in voltdb voltdbprometheusbl voltdbprometheus voltdb-node-exporter awscfboot prometheus
	# Stripped it down - only need to be able to restart volt after a reboot.
	for i in voltdb 
	do
	  sudo cp ${i}.service /lib/systemd/system/${i}.service
	  # Leave it disabled for now
	  sudo systemctl disable ${i}.service
	done

	# untar kafka
	if [ ! -d "kafka_${Kafka_Ver}" ] ; then
 	  tar -xzf kafka_${Kafka_Ver}.tgz
	  cp kafka_server.properties kafka_${Kafka_Ver}/config/server.properties
	  #mkdir /voltdbdata/kafka
	fi

	###---- Call filesystem.sh to setup external disks
    
	# Do the right thing depending on drive type - still a bit of a hack
	# Makes assumptions - 
	# * only 2 data disks
	# * if the controller is nvme you only get nvme drives and you skip the first one
	# * if the controller is scsi - skip the first 2, one is / and one is /tmp
	if [ ${#nvme_drives[@]} -ne 0 ] ; then
      for nvme in "${nvme_drives[@]:1}"
        do
          sudo bash ./filesystem.sh ${nvme} ${data_mnt}${disk_num}
          #echo "sudo bash ./filesystem.sh ${nvme} ${data_mnt}${i}"
          disk_num=$((++disk_num))
      	done
    fi
    if [ ${#sd_drives[@]} -ne 0 ] ; then
      for sd in "${sd_drives[@]}"
        do
          sudo bash ./filesystem.sh ${sd} ${data_mnt}${disk_num}
          #echo "sudo bash ./filesystem.sh ${sd} ${data_mnt}${i}"
          disk_num=$((++disk_num))
        done
    fi

	# services that start disabled  (don't need right now)
	#for i in grafana-server voltdb
	#do
	#  sudo systemctl disable ${i}.service
    #done

	sleep 10
	
	###---- End System
}


function setup_prometheus () {
	# Don't do this - we setup Node Exporter elsewhere
	PromVer="2.36.1"
	PromBin="prometheus-${PromVer}.linux-amd64.tar.gz"
	PromLink="https://github.com/prometheus/prometheus/releases/download/v${PromVer}/prometheus-${PromVer}.linux-amd64.tar.gz"
	PROMSERVER_PORT=9102
	MYCLUSTERID=$(cat /home/ubuntu/.voltclusterid)
	VOLTHOSTS=$(cat /home/ubuntu/.vdbhostnames)
	
	## Disable node_exporter as it's broken.
	###--- We don't install it in the first place
	#sudo service prometheus-node-exporter stop
	#sudo rm /etc/systemd/system/multi-user.target.wants/prometheus-node-exporter.service
	#sudo rm /lib/systemd/system/prometheus-node-exporter.service
 
	# Get Prometheus - specific version
	rm $PromBin 2> /dev/null
	wget $PromLink
	gunzip $PromBin
	tar xvf $PromBin
	rm $PromBin 2> /dev/null

	if [ "$VOLTHOSTS" = "localhost" ] ; then
		cat prometheus.yml.template | sed '1,$s/VOLTDB_CLUSTER_NAME/Site'${MYCLUSTERID}'/g' > prometheus.yml
	else
		cat prometheus.yml.template | sed '1,$s/VOLTDB_CLUSTER_NAME/Site'${MYCLUSTERID}'/g'  | grep -v localhost > prometheus.yml
		echo -n "             - targets: [" >> prometheus.yml

		COMMA=

		for i in `echo $VOLTHOSTS | sed '1,$s/,/ /g'`
		  	do
		   	for p in 9100 9101 9102
				do
					echo -n "${COMMA}'${i}:${p}'" >> prometheus.yml
					COMMA=","
			  	done
			done
		echo  "['localhost:9100']" >> prometheus.yml
	fi
	
	# Why?
	#sudo cp prometheus.yml /etc/prometheus/prometheus.yml

	# Not going to run it as a service
	#for i in status stop status start status
	#	do
	#		date
	#		sudo systemctl  ${i} prometheus.service 
	#	done

	exit 0

}

###================================== End Functions ============================================###

###---- Run functions
setup_env
setup_system
#setup_prometheus

# So we can skip running it again with Ansible
touch $HOME/.part1_ran