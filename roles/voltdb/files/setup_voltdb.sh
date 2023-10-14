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
JAVA_BUILD_VERSION="jdk-11.0.4"
JAVA_FILE_VERSION=${JAVA_BUILD_VERSION}_linux-x64
VOLT_VERSION="11.4"
Kafka_Ver="2.13-2.6.0"

###---- Check Java version
if 
	[ ! -d ${JAVA_BUILD_VERSION} ]
then
	tar xzf ${JAVA_FILE_VERSION}_bin.tar.gz
fi

# Are we using Azure nvme controller or regular sd controller?
# sd_drives will always have one drive in it, if not using NVME, nvme_drives wil be empty
nvme_drives=($(ls -l /dev/disk/by-path | grep nvme | grep -v part | awk '{print substr($11, 7)}' | sort))
sd_drives=($(ls -l /dev/disk/by-path | grep sd | grep -v part | awk '{print substr($11, 7)}' | sort))

# Some Defaults for the data disks
disk1="nvme0n2"
disk2="nvme0n3"
data_mnt="/voltdbdatassd"
MOUNTPOINT=$HOME
MOUNTPOINT_SSD1=${data_mount}1
MOUNTPOINT_SSD2=${data_mount}2


# Need this for .vdbhosts
eth0IP=$(ip -4 -o addr show dev eth0| awk '{split($4,a,"/");print a[1]}')

# Hardcode for automation
#if [ "$#" != "1" ] ; then
#	echo Usage: $0 voltdb_version
#	exit 1
#fi


# Settings for a default XML config file
SITESPERHOST=8
CMDLOGDIR=${MOUNTPOINT}/voltdbroot/cmdlog
PASSWD=admin
KFACTOR=0
CMDLOGGING=true
CMDLOG_DIR=${MOUNTPOINT_SSD1}/voltdbroot/cmdlog
SNAPSHOT_DIR=${MOUNTPOINT_SSD2}/voltdbroot/snapshot
AUTOSNAPSHOT_DIR=${MOUNTPOINT_SSD2}/voltdbroot/snapshots


# Export for functions
export SITESPERHOST CMDLOGDIR PASSWD KFACTOR CMDLOGGING CMDLOG_DIR SNAPSHOT_DIR AUTOSNAPSHOT_DIR
export eth0IP Volt_VERSION JAVA_BUILD_VERSION JAVA_FILE_VERSION Kafka_Ver
export disk1 disk2 data_mnt MOUNTPOINT MOUNTPOINT_SSD1 MOUNTPOINT_SSD2


###====================================== Functions ============================================###
###                          Should not need to edit below this line                            ###

function kill_volt () {
  ###--- Remove pre-existing/running VoltDB - why is running?
  # Grab the PID
  VPID=`ps -deaf | grep org.voltdb.VoltDB | grep java | grep -v grep | awk '{ print $2}'`

  if [ "$PID" != "" ]
  then
	  kill -9 $VPID
  fi
}


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
	#for i in grafana-server voltdb
	#do
	#  sudo systemctl disable ${i}.service
    #done

	sleep 10
	
	###---- End System
}


function clean_up () {
  # Cleanup folders - not sure why we do this but hey - why not?
  if [ -d "${MOUNTPOINT}/voltdbroot" ] ; then
  	sudo chown -R ${USER}:${USER} ${MOUNTPOINT}/voltdbroot
	  find ${MOUNTPOINT}/voltdbroot -xdev -mindepth 1 -delete
  fi

  if [ -d "${MOUNTPOINT_SSD1}/voltdbroot" ] ; then
	  sudo chown -R ${USER}:${USER} ${MOUNTPOINT_SSD1}/voltdbroot
	  find ${MOUNTPOINT_SSD1}/voltdbroot -xdev -mindepth 1 -delete
  fi

  if [ -d "${MOUNTPOINT_SSD2}/voltdbroot" ] ; then
	  sudo chown -R ${USER}:${USER} ${MOUNTPOINT_SSD2}/voltdbroot
	  find ${MOUNTPOINT_SSD2}/voltdbroot -xdev -mindepth 1 -delete
  fi

  # Fix topics_data issue - see ENG-21379
  mkdir ${MOUNTPOINT_SSD2}/voltdbroot/topics_data 2> /dev/null
  rm -rf ${HOME}/voltdbroot/topics_data
  ln -s ${MOUNTPOINT_SSD2}/voltdbroot/topics_data ${HOME}/voltdbroot/topics_data

}


function create_config () {
  ###---- Create the default cluster configuration XML file.

  # Create the folders we need:
  mkdir -p $CMDLOG_DIR 2> /dev/null
  mkdir -p $SNAPSHOT_DIR 2> /dev/null

  # Go ahead and create a sample XML file.
  cat single_instance_config.xml | sed '1,$s/'PARAM_PASSWORD'/'${PASSWD}'/g' \
    | sed '1,$s/'PARAM_KFACTOR'/'${KFACTOR}'/g' \
    | sed '1,$s/'PARAM_CMDLOG_ENABLED'/'${CMDLOGGING}'/g' \
    | sed '1,$s/'PARAM_SYNC'/'false'/g' \
    | sed '1,$s/'PARAM_SITESPERHOST'/'${SITESPERHOST}'/g' \
    | sed '1,$s_'PARAMCMDLOGDIR'_'${CMDLOG_DIR}'_g' \
    | sed '1,$s_'PARAMCMDSNAPSHOTDIR'_'${SNAPSHOT_DIR}'_g' \
    | sed '1,$s_'PARAMAUTOSNAPSHOTDIR'_'${AUTOSNAPSHOT_DIR}'_g' \
    > $MOUNTPOINT/voltdbroot/config.xml
  
  ### End Config
}


###================================== End Functions ============================================###


# If you don't have the 2 extra disks put everything in $HOME
if [ -d "/voltdbdata" ]
then
  MOUNTPOINT=/voltdbdata
  MOUNTPOINT_SSD1=${MOUNTPOINT}
  MOUNTPOINT_SSD2=${MOUNTPOINT}
fi

# Check for extra SSD mountpoints
if [ -d "/voltdbdatassd1" ]
then
	MOUNTPOINT_SSD1="/voltdbdatassd1"
fi

if [ -d "/voltdbdatassd2" ]
then
	MOUNTPOINT_SSD2="/voltdbdatassd2"
fi


###---- Run functions
# Part 1
setup_env
setup_system

# Load all of the paths setup in Part 1
. $HOME/.profile

# Part 2
kill_volt
clean_up
create_config


# Need this?
rm $HOME/voltdb_crash*txt 2> /dev/null

###
# We don't need to start/init the database automatically, especially if creating an AMI/VHDX
# Have that be part of initializing the DB - maybe a wrapper that creates a startup script 
# with the correct parameters?
# can probalby remove this - already done in part 1
###
sudo systemctl stop voltdb
sudo systemctl disable voltdb


# So we can skip running it again with Ansible
touch $HOME/.setup_ran
