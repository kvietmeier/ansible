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
USERCOUNT=$2
JSONSIZE=$3
DELTAPROP=$4
DURATION=1200

if 	
	[ "$ST" = "" -o "$USERCOUNT" = "" -o "$JSONSIZE" = "" -o "$DELTAPROP" = "" ]
then
	echo Usage: $0 tps usercount blobsize percent_of_changes

	exit 1
fi

cd
mkdir logs 2> /dev/null

cd voltdb-charglt/jars 

# silently kill off any copy that is currently running...
kill -9 `ps -deaf | grep ChargingDemoKVStore.jar  | grep -v grep | awk '{ print $2 }'` 2> /dev/null
kill -9 `ps -deaf | grep ChargingDemoTransactions.jar  | grep -v grep | awk '{ print $2 }'` 2> /dev/null


sleep 2 

DT=`date '+%Y%m%d_%H%M'`


echo "Starting a $DURATION second run at ${ST} Transactions Per Second"
echo `date` java ${JVMOPTS}  -jar ChargingDemoKVStore.jar  `cat $HOME/.vdbhostnames`  ${USERCOUNT} ${ST} $DURATION 60 $JSONSIZE $DELTAPROP >> $HOME/logs/activity.log
java ${JVMOPTS}  -jar ChargingDemoKVStore.jar  `cat $HOME/.vdbhostnames`  ${USERCOUNT} ${ST} $DURATION 60 $JSONSIZE $DELTAPROP | tee -a $HOME/logs/${DT}_kv_`uname -n`_${ST}.lst 

exit 0
