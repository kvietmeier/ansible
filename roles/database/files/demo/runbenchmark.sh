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

###=======================================================================================###
#   Modified for Azure by:
#        Karl Vietmeier - Intel Cloud CSA
###=======================================================================================###

# Just to be sure
. $HOME/.profile

###--- vars
# Numbers are in K - so 10=10000K
ST=$1
MX=$2
INC=$3
USERCOUNT=$4
DURATION=600
JARDIR=${HOME}/voltdb-charglt/jars
HOSTS=$(tr '\n' ',' < ../../.vdbhostnames | sed 's/,$//')

###--- Setup Output
OUTPUTDIR=${HOME}/logs
OUTPUTFILE=${OUTPUTDIR}/activity.log
# the list of hosts needs to be comma seperated

# Logging directory for output
if [ ! -d $OUTPUTDIR ] ; then
  mkdir $OUTPUTDIR 2> /dev/null
fi

###--- Check input
if [ "$ST" = "" -o "$MX" = "" -o "$INC" = "" -o "$USERCOUNT" = "" ] ; then
  echo Usage: $0 start_tps max_tps increment usercount
  exit 1
fi


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

function runbenchmark () {
  # Walk through the iterations
  CT=${ST}
  
  while [ "${CT}" -le "${MX}" ] ; do
  
    DT=$(date '+%Y%m%d_%H%-M-%S')
    echo "Starting a $DURATION second run at ${CT} Transactions Per Millisecond"
    echo $(date) java ${JVMOPTS} -jar ChargingDemoTransactions.jar $HOSTS ${USERCOUNT} ${CT} ${DURATION} 60 >> ${OUTPUTFILE}
    java ${JVMOPTS} -jar ChargingDemoTransactions.jar $HOSTS ${USERCOUNT} ${CT} ${DURATION} 60 
  
    if [ "$?" = "1" ] ; then
      break;
    fi

    CT=`expr $CT + ${INC}`

  done
}
### End Functions


###--- Main
cd $JARDIR
# Use function to silently kill off any copy that is currently running...
killbench
runbenchmark

exit 0
