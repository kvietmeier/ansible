#!/usr/bin/bash -x
###======================================================================#
###  Bootstrap the VoltDB demo cluster
###
###  Modified for Azure by:
###     Karl Vietmeier
###
###======================================================================#


# Have I already run once?  Exit if you have
STATFILE=$HOME/.vwrun.txt

if [ -f $STATFILE ]; then
    echo $0 already done... > ${HOME}/.alreadydone
	echo "Exiting................."
	exit 1
else
	touch $STATFILE 
fi

###=====================================================================================###
#     Parameters for setting up/running volt brought in as command line parameters
#
# Usage: ./voltwrangler $1 $2 $3 $4 $5 $6 $7 $8 $9 $10 $11 $12 $13
# 
# On AWS this is run from the CloudFormation script on image startup/instance creation
# through clouid-init   
# 

###- Hard coded them
PARAM_LOCAL_IP_STRING="10.1.12.5,10.1.12.6,10.1.12.7,10.1.12.8"
KFACTOR=8
CMDLOGGING=YES
PASSWORD="idontknow"  # Database Password
DEMONAME="voltdb-charglt"
ITYPE="Standard_E2bds_v5"   # Instance type of VM - why needed?
SPH=3
INSTANCE_ID=0   # Don't know what it is
PRIV_IP="10.1.12.4"   # IP of "extra node"
NODECOUNT=3
LURKER=YES   # Always yes
USESSD=Y
CLUSTERID="0"

echo $*  > /home/ubuntu/voltwrangler_params.dat

###================================ End Parameters =====================================###

### Vars
PARAM_LOCAL_HOST=""
VOLT_VERSION=11.4
VDBHOSTS=$(tr '\n' ',' < ../../.vdbhostnames | sed 's/,$//')
DEMODIR=${HOME}/voltdb-charglt

# Files to edit
TFILE=/home/ubuntu/bin/cluster_config.xml
CFILE=/home/ubuntu/bin/actual_configfile.xml
VEXEC=`ls /home/ubuntu/${VOLT_VERSION}/bin/voltdb`

# Output directories - defaults in case there aren't additional data drives
SNAPSHOT_DIR=/voltdbdata/voltdbroot/snapshot
AUTOSNAPSHOT_DIR=/voltdbdata/voltdbroot/snapshots
CMDLOG_DIR=/voltdbdata/voltdbroot/cmdlog


###=====================================================================================###

# We will always use SSD in our testing
if [ -z $USESSD ] ; then
  USESSD=N
fi

# Why is this here - it appears to do nothing?  It will never fall through to else
# And why set clusterID to an empty string?
if [ "$CLUSTERID" = "0" ] ; then
  # We arent using XDCR, so remove dr lines from config file
  CLUSTERID=""
  NEED_DR_GREP_PATTERN="NEED_DR"
else
  NEED_DR_GREP_PATTERN="alongcomplicatedstringthatisntinthexml"
fi

# Need to have voltdb service files setup (setup_part_1/2 do this)
echo "stopping voltdb service..."
sudo systemctl stop voltdb
sudo systemctl disable voltdb

# Azure VMs use chrony (Can force this with Ansible as well)
echo "making sure chrony is correct and in sync"
chronyc makestep

# Function makes it easier to comment it out
function setupdirs () {
  # If snapshot mountpoints exist on extra data drives - create folders
  # Requires 2 nvme drives

  # Why are we doing this?  
  # These already exist they are created by "filesystem.sh" during setup_part1 run
  
  # Get rid of extra directories
  if [ -d /voltdbdata/ ] ; then
    rm -rf /voltdbdata
  fi

  if [ -d /voltdbdatassd2/voltdbroot ] ; then
    SNAPSHOT_DIR=/voltdbdatassd2/voltdbroot/snapshot
    AUTOSNAPSHOT_DIR=/voltdbdatassd2/voltdbroot/snapshots
    mkdir -p ${SNAPSHOT_DIR}
    chown -R ubuntu:ubuntu ${SNAPSHOT_DIR}
  fi

  if [ -d /voltdbdatassd1/voltdbroot ]  ; then
    CMDLOG_DIR=/voltdbdatassd1/voltdbroot/cmdlog
    mkdir -p ${CMDLOG_DIR}
    chown -R ubuntu:ubuntu ${CMDLOG_DIR}
  else
    if [ -d /voltdbdatassd2/voltdbroot ] ; then
      CMDLOG_DIR=/voltdbdatassd2/voltdbroot/cmdlog
      mkdir -p ${CMDLOG_DIR}
      chown -R ubuntu:ubuntu ${CMDLOG_DIR}
    fi
  fi
}

function create_xml () {
  # Create the XML config file to init the database
  cat $TFILE | sed '1,$s/PARAM_SITES_PER_HOST/'${SPH}'/g' | \
  sed '1,$s/PARAM_CLUSTER_ID/'${CLUSTERID}'/g' | \
  sed '1,$s/PARAM_CMDLOGGING/'${CMDLOGGING}'/g' | \
  sed '1,$s_'PARAMCMDLOGDIR'_'${CMDLOG_DIR}'_g' | \
  sed '1,$s_'PARAMCMDSNAPSHOTDIR'_'${SNAPSHOT_DIR}'_g' |  \
  sed '1,$s_'PARAMAUTOSNAPSHOTDIR'_'${AUTOSNAPSHOT_DIR}'_g' |  \
  grep -v $NEED_DR_GREP_PATTERN | \
  sed '1,$s/^NEED_DR//g' |  \
  sed '1,$s/PARAM_KFACTOR/'${KFACTOR}'/g' > $CFILE
}

setupdirs
create_xml


# Already done but no harm in overwriting it
echo creating /home/ubuntu/.vdbhosts...
echo -n $PARAM_LOCAL_IP_STRING > /home/ubuntu/.vdbhosts
chown ubuntu /home/ubuntu/.vdbhosts

echo ${CLUSTERID} > /home/ubuntu/.voltclusterid

# I already have a valid /etc/hosts file
# Don't need this
#echo editing /etc/hosts...
#
#sudo chmod 777 /etc/hosts
#sudo echo "" >> /etc/hosts
#sudo echo "# VoltDB Hosts" >> /etc/hosts
#sudo echo "" >> /etc/hosts

CT=01
for i in `echo $PARAM_LOCAL_IP_STRING | sed '1,$s/,/ /g'`
do
	EXIST=`grep vdb-${CT} /etc/hosts` 
    
	if
		[ "$EXIST" = "" ]
	then
		sudo echo $i vdb-${CT}  >> /etc/hosts
		IPDASHNAME=ip-`echo $i | tr '.' '-'`
		sudo echo $i ${IPDASHNAME}  >> /etc/hosts
	fi

	PARAM_HOST_LIST="${PARAM_HOST_LIST},vdb-${CT}"
	CT=`expr $CT + 1`
done
sudo chmod 644 /etc/hosts

PARAM_HOST_LIST=`echo ${PARAM_HOST_LIST} | sed '1,$s/^,//g'`

# Should have this already too
echo creating /home/ubuntu/.vdbhostnames with ${PARAM_HOST_LIST}...
echo ${PARAM_HOST_LIST} > /home/ubuntu/.vdbhostnames
cat /home/ubuntu/.vdbhostnames
VDBHOSTS=`cat /home/ubuntu/.vdbhostnames`
chown ubuntu:ubuntu /home/ubuntu/.vdbhostnames

# Initialize the DB
echo calling init
sudo rm -rf /home/ubuntu/voltdbroot/*
sudo -u ubuntu /home/ubuntu/bin/reinit_voltdb.sh /home/ubuntu/voltdbroot $CFILE
cat /home/ubuntu/voltdbroot/config/deployment.xml


# Fix topics_data issue - see ENG-21379
if [ -d /voltdbdatassd2/voltdbroot ] ; then
	mkdir /voltdbdatassd2/voltdbroot/topics_data 2> /dev/null
	rm -rf /home/ubuntu/voltdbroot/topics_data
	ln -s /voltdbdatassd2/voltdbroot/topics_data /home/ubuntu/voltdbroot/topics_data
	sudo chown ubuntu:ubuntu /voltdbdatassd2/voltdbroot/topics_data
fi

sh /home/ubuntu/bin/prometheusserver_configure.sh

### This runs on "Extra Node" - turn off the DB
if [ "$LURKER" = "YES" ]
then
	sudo systemctl stop voltdb.service
	sudo systemctl disable voltdb.service

    # Why not just start it?
	for i in grafana-server
	do
		echo starting service ${i}...
		sudo systemctl start ${i}.service
		sudo systemctl enable ${i}.service
	done

	grafana-cli admin reset-admin-password $PASSWORD

	cd  /home/ubuntu

	sudo -u ubuntu bin/waituntilclustersizeisx.sh $NODECOUNT
    sudo -u ubuntu bin/setup_runoncepercluster.sh $VDBHOSTS

    # Grabbing the demo repo
	if [ "$DEMONAME" = "Running_DB" ]
	then
		echo "VoltDB is running"
	else	
	 	if [ ! -d $DEMODIR ] ; then
			# Clone the demo if we don't have it already
			sudo -u ubuntu git clone https://github.com/srmadscience/${DEMONAME}.git
		fi

		sudo -u ubuntu sh /home/ubuntu/${DEMONAME}/scripts/setup.sh $VDBHOSTS
	fi
	
	cd bin

else
    # We are running on a DB node
    # Disable Prometheus?
	for i in voltdb voltdbprometheusbl voltdbprometheus
	do
		echo stopping service ${i}...
		sudo systemctl stop ${i}.service
		sudo systemctl disable ${i}.service

	done
fi


