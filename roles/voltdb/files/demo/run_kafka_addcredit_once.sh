#!/bin/sh

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

USERCOUNT=$1
ST=$2
DURATION=$3
MAXCREDIT=$4
KPORT=9092

if 	
	[ "$ST" = "" -o "$USERCOUNT" = "" -o "$DURATION" = "" -o "$MAXCREDIT" = "" ]
then
	echo Usage: $0 usercount tps duration max_credit

	exit 1
fi

cd
mkdir logs 2> /dev/null

cd voltdb-charglt/jars 


DT=`date '+%Y%m%d_%H%M'`

KHOSTS=`cat $HOME/.vdbhostnames | sed '1,$s/,/:'${KPORT}',/g'`:${KPORT}

echo "Starting a $DURATION second run at ${ST} Transactions Per Second"
echo `date` java ${JVMOPTS}  -jar KafkaCreditDemo.jar ${KHOSTS} ${USERCOUNT} ${ST} $DURATION $MAXCREDIT  >> $HOME/logs/activity.log
java ${JVMOPTS}  -jar KafkaCreditDemo.jar ${KHOSTS} ${USERCOUNT} ${ST} $DURATION $MAXCREDIT | tee -a $HOME/logs/${DT}_kafka__`uname -n`_${ST}.lst
sleep 2 

exit 0
