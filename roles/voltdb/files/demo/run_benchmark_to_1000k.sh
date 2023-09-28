#!/bin/sh

BNAME=$1

if
	[ "$BNAME" = "" ]
then
	echo Usage: nohup sh $0 filename \& 
	exit 1
fi

sh check_aws_network_limits.sh
sh -x runlargebenchmark.sh 90 2000 10 4000000 10  > ${BNAME}_oltp.lst
sh check_aws_network_limits.sh
sleep 60
sh -x runlargekvbenchmark.sh 90 2000 10 4000000 100 50 10  > ${BNAME}_kv.lst
sh check_aws_network_limits.sh


