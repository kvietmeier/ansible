#!/bin/sh

BNAME=$1

if
	[ "$BNAME" = "" ]
then
	echo Usage: nohup sh $0 filename \& 
	exit 1
fi

sh check_aws_network_limits.sh 
sh -x runbenchmark.sh 5 100 5 4000000  > ${BNAME}_oltp.lst
sh check_aws_network_limits.sh 
sleep 60
sh -x runkvbenchmark.sh 5 100 5 4000000 100 50  > ${BNAME}_kv.lst
sh check_aws_network_limits.sh 
