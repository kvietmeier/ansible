#!/bin/sh

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
#   This sets up databse stats export to Prometheus
#
#   Modified for Azure by:
#        Karl Vietmeier - Intel Cloud CSA
#
###=======================================================================================###

cd $HOME
. ${HOME}/.profile


###--- Vars
LOGDIR=${HOME}/logs
PROMETHEUSBL_PORT=9102

# Commamd gets really long.....
JavaFlag1="--webserverport=${PROMETHEUSBL_PORT}"
JavaFlag2="--add-opens=java.base/sun.nio.ch=ALL-UNNAMED"
JavaFlag3="--procedureList=PROCEDUREPROFILE,ORGANIZEDTABLESTATS,ORGANIZEDINDEXSTATS,SNAPSHOTSTATS,ORGANIZEDSQLSTMTSTATS,${BL_PROCEDURES}"

# These are for bug fixes etc.
#"--add-opens=java.base/jdk.internal.ref=ALL-UNNAMED"
#"--add-opens=java.base/sun.nio.ch=ALL-UNNAMED"



###--- End Vars


###---- Logging directory for output
if [ ! -d $LOGDIR ] ; then
  mkdir $LOGDIR 2> /dev/null
fi

LOGFILEBL=${LOGDIR}/start_voltdbprometheusbl_if_needed`date '+%m%d%y%H-%M'`.log
touch $LOGFILEBL
echo `date` "configuring prometheus " | tee -a $LOGFILEBL


#
# See if we need to start prometheus client for voltdb
#

curl -m 1 localhost:${PROMETHEUSBL_PORT}/metrics > /tmp/$$curl.log

if [ -s /tmp/$$curl.log ] ; then
  echo `date` "voltdbprometheusbl.jar already running" | tee -a  $LOGFILEBL
else
	# kill it if its hung...
 	OLDPROCESS=`ps -deaf | grep voltdbprometheusbl.jar | grep -v grep | awk '{ print $2 }'`
	
	if [ "$OLDPROCESS" != "" ] ; then
	  echo `date` killed process $OLDPROCESS
	  kill -9 $OLDPROCESS
	fi

	cd ${HOME}/bin
	echo `date` "starting voltdbprometheusbl.jar on port $PROMETHEUSBL_PORT" | tee -a  $LOGFILEBL

	#nohup java -jar voltdbprometheusbl.jar --webserverport=$PROMETHEUSBL_PORT --procedureList=PROCEDUREPROFILE,ORGANIZEDTABLESTATS,ORGANIZEDINDEXSTATS,SNAPSHOTSTATS,ORGANIZEDSQLSTMTSTATS,${BL_PROCEDURES} >>  $LOGFILEBL 2>&1  &
	nohup java -jar voltdbprometheusbl.jar  ${JavaFlag1} ${JavaFlag2} ${JavaFlag3} >>  $LOGFILEBL 2>&1  &
        
	PPID=`ps -deaf | grep voltdbprometheusbl.jar | grep java | grep -v grep | awk '{ print $2}'`
	echo $PPID > ${HOME}/.voltdbprometheusbl.PID
fi

rm /tmp/$$curl.log

exit 0
