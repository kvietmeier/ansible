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

TPS=200
JARDIR=$HOME/voltdb-charglt/jars
OUTPUTDIR=${HOME}/logs
OUTPUTFILE=${OUTPUTDIR}/activity.log

# the list of hosts needs to be comma seperated
HOSTS=$(tr '\n' ',' < ${HOME}/.vdbhostnames | sed 's/,$//')

# We need an output dir
if [ ! -d $OUTPUTDIR ] ; then
  mkdir $OUTPUTDIR 2> /dev/null
fi

cd $JARDIR

echo `date` java  ${JVMOPTS}  -jar DeleteChargingDemoData.jar $HOSTS $TPS >> $OUTPUTFILE
java  ${JVMOPTS}  -jar DeleteChargingDemoData.jar  $HOSTS $TPS
