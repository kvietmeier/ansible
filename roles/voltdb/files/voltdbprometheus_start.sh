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
#
#   This starts the custom Prometheus node_exporter provided with the Volt binary tarball.
#   In- 
#      ${HOME}/voltdb*${VOLT_VERSION}/tools/monitoring/prometheus
#
#   Modified for Azure by:
#        Karl Vietmeier - Intel Cloud CSA
#
#   * Changed logging dir
#
#   
#
###=======================================================================================###

cd $HOME
. ${HOME}/.profile


### Vars - 
PROMETHEUS_PORT=9101
LOGDIR=${HOME}/logs


###---- Logging directory for output
if [ ! -d $LOGDIR ] ; then
  mkdir $LOGDIR 2> /dev/null
fi

LOGFILE=${LOGDIR}/start_voltdbprometheus_if_needed`date '+%m%d%y%H-%M'`.log
touch $LOGFILE
echo `date` "configuring prometheus " | tee -a $LOGFILE


# See if we need to start prometheus client for voltdb
curl -m 1 localhost:${PROMETHEUS_PORT} > /tmp/$$curl.log

if [ -s /tmp/$$curl.log ] ; then
  echo `date` "voltdb-prometheus already running" | tee -a  $LOGFILE
else
  # kill it if its hung...
  OLDPROCESS=`ps -deaf | grep voltdb-prometheus| grep -v grep | awk '{ print $2 }'`
	
  if [ "$OLDPROCESS" != "" ] ; then
	echo `date` killed process $OLDPROCESS
	kill -9 $OLDPROCESS
  fi

  # Start the custom exporter
  cd ${HOME}/voltdb*/tools/monitoring/prometheus
  echo `date` " starting voltdb-prometheus on port $PROMETHEUS_PORT" | tee -a  $LOGFILE
  nohup ./voltdb-prometheus --webserverport=$PROMETHEUS_PORT >  $LOGFILE  2>&1 &

  PPID=`ps -deaf | grep voltdb-prometheus | grep java | grep -v grep | awk '{ print $2}'`
  echo $PPID > ${HOME}/.voltdbprometheus.PID

fi

rm /tmp/$$curl.log
touch ${HOME}/.custom_ne_started

exit 0