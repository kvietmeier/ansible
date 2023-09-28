#!/usr/bin/bash

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
DURATION=1200
OUTPUTDIR=${HOME}/logs
JARDIR=$HOME/voltdb-charglt/jars
DT=`date '+%Y%m%d_%H%M'`

# the list of hosts needs to be comma seperated
HOSTS=$(tr '\n' ',' < ../../.vdbhostnames | sed 's/,$//')

if 	[ "$ST" = "" -o "$USERCOUNT" = "" ] ; then
  echo Usage: $0 tps usercount
  exit 1
fi

# Logging directory for output
if [ ! -d $OUTPUTDIR ] ; then
  mkdir $OUTPUTDIR 2> /dev/null
fi

cd $JARDIR

### Functions:
function killbench () {
  # Need to kill off any running java threads
  
  # Get the first PID
  PID=$(ps -deaf | grep ChargingDemoTransactions.jar  | grep -v grep | awk '{ print $2 }')
  
  if [ -z $PID] ; then
    echo "No java threads running"
  else 
    echo "Previous benchmark still running, reaping the threads"
  fi

  # Reap the PIDs - loop until none are left
  until [ -z $PID ]
  do
    kill -9 $PID
    sleep 2
    PID=$(ps -deaf | grep ChargingDemoTransactions.jar  | grep -v grep | awk '{ print $2 }')
  done
}

### End Functions

# Kill existing benchmark threads
killbench

# Kickoff run
echo "Starting a $DURATION second run at ${ST} Transactions Per Millisecond"
echo `date` java ${JVMOPTS}  -jar ChargingDemoTransactions.jar $HOSTS ${USERCOUNT} ${ST} $DURATION 60 >> ${OUTPUTDIR}/activity.log
java ${JVMOPTS}  -jar ChargingDemoTransactions.jar $HOSTS ${USERCOUNT} ${ST} $DURATION 60 | tee -a ${OUTPUTDIR}/${DT}_charging_`uname -n`_${ST}.lst 

exit 0
