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
###=======================================================================================###


cd $HOME
. ${HOME}/.profile

# Vars
log_dir="${HOME}/logs"
volt_ver=11.4
VDBHOSTS=$(tr '\n' ',' < ${HOME}/.vdbhostnames | sed 's/,$//')
DEMODIR=${HOME}/voltdb-charglt
BINDIR=${HOME}/voltdb-ent-${volt_ver}/bin/
MOUNTPOINT=${HOME}

# Setup hosts  (why??)
origVDBHOSTS=`cat ${HOME}.vdbhosts`
VDBHOSTNAMES=`cat ${HOME}/.vdbhostnames`

# Check to see if we have the extra disks
# /voltdbdata exists if we didn't have the extra disks when we ran setup
if [ -d "/voltdbdata" ] ; then
   MOUNTPOINT=/voltdbdata
fi


# Setup logging
mkdir -p ${MOUNTPOINT}/log
LOGFILE=${MOUNTPOINT}/log/stop_voltdb_if_needed`date '+%y%m%d'`.log
touch $LOGFILE


# See if VoltDB already running...
VRUN=`ps -deaf | grep org.voltdb.VoltDB | grep java | grep -v grep`


if [ -z ${VRUN} ] ; then
  echo `date` Not running... | tee -a  $LOGFILE
else	
  echo `date` voltdb_stop.sh: Shutting down node...  | tee -a $LOGFILE

  voltadmin shutdown --save --host=localhost 2>&1 >>  $LOGFILE  

  VHNAME=`uname -n`
  VHID=`echo "exec @SystemInformation overview;" | sqlcmd | grep $VHNAME| awk '{ print $1 }'`
  echo "exec @StopNode ${VHID}" | sqlcmd

  echo `date` voltdb_stop.sh: Shutting finished...  | tee -a $LOGFILE

fi

exit 0
