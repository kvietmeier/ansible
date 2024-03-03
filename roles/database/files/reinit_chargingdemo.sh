#!/usr/bin/bash
####=======================================================================================###
#   Reinitialize the database after cleaning up the directories
# 
#   Modified for Azure by:
#        Karl Vietmeier - Intel Cloud CSA
###=======================================================================================###


# insurance, not really required
. ${HOME}/.profile
cd $HOME

# Vars
demo_cfg="demo_cluster_config.xml"
demodbdir="chargingdb"
license="license.xml"
volt_ver="11.4"
log_dir="${HOME}/logs"


# Track that we did this - not sure why
if [ ! -d ${log_dir} ] ; then
  mkdir -p ${log_dir} 2> /dev/null
  LOGFILE=${log_dir}/reinitialize_voltdb-`date '+%y%m%d'-%H%M`.log
  touch $LOGFILE
else
  LOGFILE=${log_dir}/reinitialize_voltdb-`date '+%y%m%d'-%H%M`.log
  touch $LOGFILE
fi


# If you don't have the 2 extra disks put everything in $HOME
MOUNTPOINT=$HOME

if [ -d "/voltdbdata" ] ; then
  MOUNTPOINT=/voltdbdata
  MOUNTPOINT_SSD1=${MOUNTPOINT}
  MOUNTPOINT_SSD2=${MOUNTPOINT}
fi

# Check for extra SSD mountpoints
if [ -d "/voltdbdatassd1" ] ; then
  MOUNTPOINT_SSD1="/voltdbdatassd1"
fi

if [ -d "/voltdbdatassd2" ] ; then
  MOUNTPOINT_SSD2="/voltdbdatassd2"
fi


# Cleanup folders
if [ -d "${MOUNTPOINT_SSD1}/voltdbroot" ]
then
	sudo chown -R ${USER}:${USER} ${MOUNTPOINT_SSD1}/voltdbroot
	find ${MOUNTPOINT_SSD1}/voltdbroot -xdev -mindepth 1 -delete
fi

if [ -d "${MOUNTPOINT_SSD2}/voltdbroot" ]
then
	sudo chown -R ${USER}:${USER} ${MOUNTPOINT_SSD2}/voltdbroot
	find ${MOUNTPOINT_SSD2}/voltdbroot -xdev -mindepth 1 -delete
fi

# Check if volt is running
volt_pid=$(ps -ef | grep voltdb | grep -v grep | grep -v voltdbprometheusbl | awk '{print $2 }')

# Fix topics_data issue - see ENG-21379
mkdir ${MOUNTPOINT_SSD2}/voltdbroot/topics_data 2> /dev/null
rm -rf ${HOME}/voltdbroot/topics_data
ln -s ${MOUNTPOINT_SSD2}/voltdbroot/topics_data ${HOME}/voltdbroot/topics_data

### Functions - 
function reinit ()
{
  # Reinitialize the demo
  echo "Coast is clear - Re-init"
  echo `date` calling init | tee -a $LOGFILE
  voltdb init --force --dir=${HOME}/${demodbdir} --config=${HOME}/${demo_cfg} --license=${HOME}/${license}| tee -a $LOGFILE
}

### Do it
if [ ! -z $volt_pid ] ; then
  echo "Voldb is running - kill it"
  kill $volt_pid
  reinit
else
  reinit
fi



