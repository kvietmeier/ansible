#!/usr/bin/bash
# Wait until the cluste is up
# Called from voltwrangler

. ${HOME}/.profile

if [ "$1" = "" ] ; then
	echo "$0 clustersize"
	exit 1
fi

echo `date` waituntilclustersizeisx.sh : wait until cluster size is $1

DONE=NO

while [ "$DONE" = "NO" ]
do

	CSIZE=$(echo "exec @SystemInformation OVERVIEW;" | sqlcmd --servers=vdb-02 | grep IPADDRESS | wc -l)
	echo $CSIZE

	if 
		[ "$CSIZE" -eq "$1" ]
	then
		DONE=YES
	fi

	echo `date` waituntilclustersizeisx.sh : cluster size is $CSIZE
	sleep 10

done


