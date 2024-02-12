#!/usr/bin/bash
# Kill running benchmark threads - you have to loop because the bmark script will 
# keep spawning new ones until it is done.

. $HOME/.profile

# Get the first PID
PID=$(ps -deaf | grep ChargingDemoTransactions.jar  | grep -v grep | awk '{ print $2 }')

function kill_threads () {

until [ -z $PID ]
  do
    echo "Killing $PID"
    kill -9 $PID
    sleep 2
    PID=$(ps -deaf | grep ChargingDemoTransactions.jar  | grep -v grep | awk '{ print $2 }')
    echo $PID
  done

}

kill_threads

