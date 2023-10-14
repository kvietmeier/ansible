#!/usr/bin/bash
###=======================================================================================###
#   Second setup script for creating a VoltDB image 
###=======================================================================================###
#
#   Requirements:
#    	* Ubuntu 18.04 or newer
#		  * Root volume >30GB
#		  * 2 data volumes >128GB
#		  * a $HOME/bin directory with the VoltDB utility scripts and utility packages
#		  * Run setup_part_1.sh
#		  * Mountpoints created and added to /etc/fstab by Part 1
#	
#	  Related/Required scripts/files:
#		  * none
#
#   Modified for Azure by:
#        Karl Vietmeier - Intel Cloud CSA
# 
#   Usage:
#   	> setup_part_2.sh
#       
###=======================================================================================###

# Load all of the paths setup in Part 1
. $HOME/.profile

# Change into the volt bin/scripts folder
# Make sure we are running in the right dir....
cd "$(dirname "${BASH_SOURCE[0]}")"

MOUNTPOINT=$HOME

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

# Settings for a default XML config file
SITESPERHOST=8                             # Adjust based on number of vCPU
CMDLOGDIR=${MOUNTPOINT}/voltdbroot/cmdlog
PASSWD=admin
KFACTOR=1                                  # We are creating clusters - set to 0 for single node
CMDLOGGING=true
CMDLOG_DIR=${MOUNTPOINT_SSD1}/voltdbroot/cmdlog
SNAPSHOT_DIR=${MOUNTPOINT_SSD2}/voltdbroot/snapshot
AUTOSNAPSHOT_DIR=${MOUNTPOINT_SSD2}/voltdbroot/snapshots


###====================================== Functions ============================================###
###                                                                                             ###

function kill_volt () {
  ###--- Remove pre-existing/running VoltDB - why is running?
  # Grab the PID
  VPID=`ps -deaf | grep org.voltdb.VoltDB | grep java | grep -v grep | awk '{ print $2}'`

  if [ "$PID" != "" ]
  then
	  kill -9 $VPID
  fi

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
    > $MOUNTPOINT/cluster_config.xml

}

###================================== End Functions ============================================###

###---- Run functions
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
touch $HOME/.part2_ran