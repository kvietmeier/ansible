#!/bin/sh

# This file is part of VoltDB.
#  Copyright (C) 2008-2022 VoltDB Inc.
#
#  Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
#  "Software"), to deal in the Software without restriction, including
#  without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
#  permit persons to whom the Software is furnished to do so, subject to
#  the following conditions:
#
#  The above copyright notice and this permission notice shall be
#  included in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
#  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
#  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#  OTHER DEALINGS IN THE SOFTWARE.

. $HOME/.profile

ST=$1
MX=$2
INC=$3
USERCOUNT=$4
JSONSIZE=$5
DELTAPROP=$6
DURATION=600

# Did we provide the correct parameters?
if [ "$ST" = "" -o "$MX" = "" -o "$INC" = "" -o "$USERCOUNT" = "" -o "$JSONSIZE" = "" -o "$DELTAPROP" = "" ] ; then
	echo Usage: $0 start_tps end_tps inc_tps usercount blobsize percent_of_changes
	exit 1
fi

JARDIR=${HOME}/voltdb-charglt/jars
cd $JARDIR

HOSTS=$(tr '\n' ',' < ../../.vdbhostnames | sed 's/,$//')

###--- Setup Output
OUTPUTDIR=${HOME}/logs
OUTPUTFILE=${OUTPUTDIR}/activity.log
# the list of hosts needs to be comma seperated

# Logging directory for output
if [ ! -d $OUTPUTDIR ] ; then
  mkdir $OUTPUTDIR 2> /dev/null
fi


# silently kill off any copy that is currently running...
kill -9 `ps -deaf | grep ChargingDemoKVStore.jar  | grep -v grep | awk '{ print $2 }'` 2> /dev/null
kill -9 `ps -deaf | grep ChargingDemoTransactions.jar  | grep -v grep | awk '{ print $2 }'` 2> /dev/null


sleep 2 

CT=${ST}

while [ "${CT}" -le "${MX}" ] ; do
	DT=`date '+%Y%m%d_%H%M'`
	echo "Starting a $DURATION second run at ${ST} Transactions Per Second"
	echo $(date) java ${JVMOPTS}  -jar ChargingDemoKVStore.jar $HOSTS ${USERCOUNT} ${CT} $DURATION 60 $JSONSIZE $DELTAPROP >> $OUTPUTFILE
	java ${JVMOPTS}  -jar ChargingDemoKVStore.jar $HOSTS ${USERCOUNT} ${CT} $DURATION 60 $JSONSIZE $DELTAPROP 

	if [ "$?" = "1" ] ; then
    	break;
    fi

	CT=`expr $CT + ${INC}`

	sleep 15
done

exit 0
