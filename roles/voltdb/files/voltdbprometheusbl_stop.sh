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
#   Modified for Azure by:
#        Karl Vietmeier - Intel Cloud CSA
#
#   https://prometheus.io/download/
#   
#   https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.linux-amd64.tar.gz
#
#   Purpose: Call to kill Prometheus
#   
###=======================================================================================###

PROMETHEUSBL_PORT=9102
LOGDIR=${HOME}/logs

cd $HOME
. ${HOME}/.profile

# Logging directory for output
if [ ! -d $LOGDIR ] ; then
  mkdir $LOGDIR 2> /dev/null
fi

LOGFILEBL=${LOGDIR}/stop_voltdbprometheusbl_if_needed`date '+%y%m%d'`.log
touch $LOGFILEBL

# See if we need to stop prometheus client for voltdb
curl -m 1 localhost:${PROMETHEUSBL_PORT} > /tmp/$$curl.log

if [ -s /tmp/$$curl.log ] ; then
  # kill it if it is running
  OLDPROCESS=$(ps -deaf | grep voltdbprometheusbl.jar | grep -v grep | awk '{ print $2 }')

  if [ "$OLDPROCESS" != "" ] ; then
	  echo `date` killed process $OLDPROCESS
	  kill  $OLDPROCESS
	  rm ${HOME}/.voltdbprometheusbl.PID 2> /dev/null
  fi

fi

rm /tmp/$$curl.log