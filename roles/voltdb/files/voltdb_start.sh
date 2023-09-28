#!/usr/bin/bash

# This file is part of VoltDB.
#  Copyright (C) 2008-2017 VoltDB Inc.
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


cd $HOME
. ${HOME}/.profile

#$ Vars
log_dir="${HOME}/logs"
VOLT_VERSION=11.4


# Setup log dir
if [ ! -d ${log_dir} ] ; then
  mkdir -p ${log_dir} 2> /dev/null
  LOGFILE=${log_dir}/start_voltdb_if_needed-`date '+%y%m%d'-%H%M`.log
  touch $LOGFILE
else
  LOGFILE=${log_dir}/start_voltdb_if_needed-`date '+%y%m%d'-%H%M`.log
  touch $LOGFILE
fi


# See if we need to re-do voltDB...
#

if [ -r "${MOUNTPOINT}/jumpstart_needed.txt" ]
then
  echo `date` "Rebuilding VoltDB..." | tee -a $LOGFILE 
  sh ${HOME}/bin/voltdb_stop.sh | tee -a $LOGFILE 
  sh ${HOME}/bin/jumpstart_voltdb.sh NOSERVICE | tee -a $LOGFILE 
  sudo rm ${MOUNTPOINT}/jumpstart_needed.txt
fi


# See if VoltDB already running...
VRUN=$(ps -deaf | grep org.voltdb.VoltDB | grep java | grep -v grep)
VDBHOSTS=$(cat ${HOME}/.vdbhostnames)

if [ -z $VRUN ]
then
  # Don't use ntp on Azure - 
  #echo `date` Checking NTP... | tee -a  $LOGFILE
  #sh -x /home/ubuntu/bin/ntpfix.sh  | tee -a  $LOGFILE
  echo `date` Starting VoltDB... | tee -a  $LOGFILE
  echo nohup voltdb start  --dir=${MOUNTPOINT}  --host=${VDBHOSTS}  | tee -a $LOGFILE 
  nohup voltdb start  --dir=${MOUNTPOINT}  --host=${VDBHOSTS} >  $LOGFILE  2>&1  &
  sleep 5
  VRUN=`ps -deaf | grep org.voltdb.VoltDB | grep java | grep -v grep | awk '{ print $2}'`
  echo $VRUN > ${HOME}/.voltdb.PID 		
else	
  echo `date` Already running... | tee -a  $LOGFILE
fi

#
# See if we need to start new relic
#

if [ -r ${HOME}/voltdb*${VOLT_VERSION}/tools/monitoring/newrelic/config/newrelic.properties ]
then
  NR=$(ps -deaf | grep voltdb-newrelic | grep -v grep | awk ' {print $2} ')

  if [ -z $NR ]
  then
    cd ${HOME}/voltdb*${VOLT_VERSION}/tools/monitoring/newrelic
    nohup ./voltdb-newrelic   | tee -a  $LOGFILE &
  else
    echo "new relic running PID $NR" | tee -a  $LOGFILE
  fi

else
  echo "new relic not in use " | tee -a  $LOGFILE
fi

exit 0