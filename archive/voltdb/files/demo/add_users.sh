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

###====================== Create users for benchmarks ======================###
#                  Required to run the other benchmark scripts
#
#   Suggested values:
#     USERCOUNT=100
#     TPMS=10/core
#     MAX_CREDIT=10000
###=========================================================================###


. $HOME/.profile

JARDIR=${HOME}/voltdb-charglt/jars
USERCOUNT=$1
TPMS=$2
MAX_CREDIT=$3
OUTPUTDIR=demo_logs
OUTPUTFILE=${OUTPUTDIR}/activity.log

# Make sure we are in the right dir
cd $JARDIR

# the list of hosts needs to be comma seperated
HOSTS=$(tr '\n' ',' < ${HOME}/.vdbhostnames | sed 's/,$//')

if [ "$USERCOUNT" = "" -o "$TPMS" = "" -o "$MAX_CREDIT" = "" ] ; then
  echo Usage: $0 usercount tpms max_credit
  echo "Using Defaults: USERCOUNT=100 TPMS=20 MAX_CREDIT=10000"
  USERCOUNT=100
  TPMS=20
  MAX_CREDIT=10000
fi

# We need an output dir should have been created by setup.sh
if [ ! -d $OUTPUTDIR ] ; then
  mkdir $OUTPUTDIR 2> /dev/null
fi


echo `date` java ${JVMOPTS} -jar CreateChargingDemoData.jar $HOSTS $USERCOUNT $TPMS $MAX_CREDIT >> $OUTPUTFILE
java ${JVMOPTS} -jar CreateChargingDemoData.jar $HOSTS $USERCOUNT $TPMS $MAX_CREDIT

