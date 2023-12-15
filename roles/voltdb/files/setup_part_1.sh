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
JAVA_BUILD_VERSION="jdk-11.0.4"
JAVA_FILE_VERSION=${JAVA_BUILD_VERSION}_linux-x64
VOLT_VERSION="11.4"
Kafka_Ver="2.13-2.6.0"

# Are we using Azure nvme controller or regular sd controller?
# sd_drives will always have one drive in it, if not using NVME, nvme_drives wil be empty
nvme_drives=($(ls -l /dev/disk/by-path | grep nvme | grep -v part | awk '{print substr($11, 7)}' | sort))
sd_drives=($(ls -l /dev/disk/by-path | grep sd | grep -v part | awk '{print substr($11, 7)}' | sort))

disk1="nvme0n2"
disk2="nvme0n3"
data_mnt="/voltdbdatassd"

# Need this for .vdbhosts
eth0IP=$(ip -4 -o addr show dev eth0| awk '{split($4,a,"/");print a[1]}')

# Hardcode for automation
#if [ "$#" != "1" ] ; then
#	echo Usage: $0 voltdb_version
#	exit 1
#fi

export eth0IP Volt_VERSION JAVA_BUILD_VERSION JAVA_FILE_VERSION Kafka_Ver
export disk1 disk2 data_mnt

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

	if [ -z $HASVOLT ] ; then
      cat ${HOME}/bin/extra_profile | sed '1,$s/PARAM_VOLTDB_VERSION/'${VOLT_VERSION}'/g' | sed '1,$s/PARAM_JAVA_VERSION/'${JAVA_BUILD_VERSION}'/g' >> $HOME/.profile
    else
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
	# Leave it disabled for now
	for  i in voltdb 
	do
	  sudo cp ${i}.service /lib/systemd/system/${i}.service
	  sudo systemctl disable ${i}.service
	done

	# untar kafka
	if [ ! -d "kafka_${Kafka_Ver}" ] ; then
 	  tar -xzf kafka_${Kafka_Ver}.tgz
	  cp kafka_server.properties kafka_${Kafka_Ver}/config/server.properties
	  #mkdir /voltdbdata/kafka
	fi

	###---- Call filesystem.sh to setup external disks
	sudo bash ./filesystem.sh ${disk1} ${data_mnt}1
	sudo bash ./filesystem.sh ${disk2} ${data_mnt}2

	# services that start disabled
	for i in grafana-server voltdb
	do
	  sudo systemctl disable ${i}.service
    done

	sleep 10
	
	###---- End System
}


###================================== End Functions ============================================###

###---- Run functions
setup_env
setup_system


# So we can skip running it again with Ansible
touch $HOME/.part1_ran
