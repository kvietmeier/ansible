#!/usr/bin/bash

# This file is part of VoltDB.
#  Copyright (C) 2008-2020 VoltDB Inc.
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
#
#   https://prometheus.io/download/
#   https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.linux-amd64.tar.gz
#
#   Purpose:  Sets up the Prometheus server on each DB node to export the Database stats.
#   
#   === Run on every DB node
#
###=======================================================================================###

cd $HOME
. ${HOME}/.profile

###---- Vars
PROMETHEUSBL_PORT=9102
LOGDIR=${HOME}/logs
log_file_name="start_voltdbprometheusbl_if_needed"


###=======================================================================================###
#    Shouldn't need to edit below this line other than to comment/uncomment functions       #



###=======================================================================================###
#    Functions - 
###=======================================================================================###


function logging () {
  # Create logfile of script run
  
  if [ ! -d $LOGDIR ] ; then
    mkdir $LOGDIR 2> /dev/null
  fi

  LOGFILE=${LOGDIR}/${log_file_name}`date '+%y%m%d'`.log
  touch $LOGFILE
  echo `date` "configuring prometheus database telemetry" | tee -a $LOGFILE
  
}

function kill_it () {
  # kill it if it is running
  
  PromPID=$(ps -deaf | grep voltdbprometheusbl.jar | grep -v grep | awk '{ print $2 }')
  if [ -n "$PromPID" ] ; then
    echo `date` killed process $PromPID
    kill -9 $PromPID
  fi
}

function start_it () {
  # Start Prometheus Server with Volt Jar to forward DB stats
  
  cd ${HOME}/bin
  echo `date` "starting voltdbprometheusbl.jar on port $PROMETHEUSBL_PORT" | tee -a  $LOGFILE

  nohup java -jar voltdbprometheusbl.jar --webserverport=$PROMETHEUSBL_PORT --procedureList=PROCEDUREPROFILE,ORGANIZEDTABLESTATS,ORGANIZEDINDEXSTATS,SNAPSHOTSTATS,ORGANIZEDSQLSTMTSTATS,${BL_PROCEDURES} >> $LOGFILE 2>&1  &

  Is_Running=$(ps -deaf | grep voltdbprometheusbl.jar | grep java | grep -v grep | awk '{ print $2}')
  echo $Is_Running > ${HOME}/.voltdbprometheusbl.PID
}

###=======================================================================================###


###---- Main
logging
kill_it
start_it


# Create a stat file of sorts doesn't work for some reason
#curl -m 1 localhost:${PROMETHEUSBL_PORT}/metrics > /tmp/${VRUN}curl.log
#echo "curl -m 1 localhost:${PROMETHEUSBL_PORT}/metrics > /tmp/${VRUN}curl.log"