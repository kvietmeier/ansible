#!/bin/sh

INALLOW=`ethtool -S ens5 | grep bw_in_allowance_exceeded | awk -F: '{ print $2 }'`
OUTALLOW=`ethtool -S ens5 | grep bw_out_allowance_exceeded | awk -F: '{ print $2 }'`

echo $0

if 
	[ "$INALLOW" -gt 0 ]
then
	echo WARNING: AWS IS THROTTLING INPUT TRAFFIC - ${INALLOW}
fi

if 
	[ "$OUTALLOW" -gt 0 ]
then
	echo WARNING: AWS IS THROTTLING OUTPUT TRAFFIC - ${OUTALLOW}
fi

