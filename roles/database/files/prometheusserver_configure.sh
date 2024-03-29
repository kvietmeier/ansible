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
#   
#   https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.linux-amd64.tar.gz
#
#   
#        === Only run on mgmt node! ===
#
###=======================================================================================###

# Run to enable debugging - uncomment to use
function debug () {
  export PS4="\$LINENO: "
  set -xv
}
#debug

. ${HOME}/.profile                                    # Make sure we get the right paths
cd "$(dirname "${BASH_SOURCE[0]}")"                   # Make sure we are running in the right dir....

###---- Vars
# Versions - 
PromVer="2.36.1"
PromBin="prometheus-${PromVer}.linux-amd64.tar.gz"
PromLink="https://github.com/prometheus/prometheus/releases/download/v${PromVer}/prometheus-${PromVer}.linux-amd64.tar.gz"

# Ports - 
#   9100: Default node_exporter
#   9101: Customized VoltDB NE
#   9102: Database Stats exporter
target_ports=(9100 9101 9102)                         # Create an array of target ports
PROMSERVER_PORT=9090

# Files/hosts etc.
MYCLUSTERID=$(cat ${HOME}/.voltclusterid)
VOLTHOSTS=$(cat ${HOME}/.vdbhostnames)
HOSTS=$(tr '\n' ',' < ${HOME}/.vdbhostnames | sed 's/,$//')
LOGDIR=${HOME}/logs

###---- End Vars

###---- Logging directory for output
if [ ! -d $LOGDIR ] ; then
  mkdir $LOGDIR 2> /dev/null
fi

LOGFILE=${LOGDIR}/start_prometheusserver_if_needed`date '+%y%m%d'`.log
touch $LOGFILE
echo "$(date) - configuring prometheus" | tee -a $LOGFILE


###=======================================================================================###
#      Setup Prometheus
###=======================================================================================###

# First get rid of the package if we have it
if [ -f $PromBin ] ; then
  rm $PromBin 2> /dev/null
fi

# Grab a new one (not sure why we do this)
wget $PromLink
tar xzf $PromBin

# Clean up
rm $PromBin 2> /dev/null

# Setup the prometheus.xml file

# Are we a single node?
if [ "$VOLTHOSTS" = "localhost" ] ; then
  cat prometheus.yml.template | sed '1,$s/VOLTDB_CLUSTER_NAME/Site'${MYCLUSTERID}'/g' > prometheus.yml

# No - then setup the DB nodes
else
  cat prometheus.yml.template | sed '1,$s/VOLTDB_CLUSTER_NAME/Site'${MYCLUSTERID}'/g'  | grep -v localhost > prometheus.yml
  echo -n "             - targets: [" >> prometheus.yml

  COMMA=

  for host in `echo $VOLTHOSTS | sed '1,$s/,/ /g'` ; do
      for port in "${target_ports[@]}" ; do
          echo -n "${COMMA}'${host}:${port}'" >> prometheus.yml
          COMMA=","
      done
  done
  
  echo  ",'localhost:9100']" >> prometheus.yml

fi

# Ovewwrite the existing one
sudo cp prometheus.yml /etc/prometheus/prometheus.yml

# Copy our unit file
sudo cp prometheus.service /usr/local/lib/systemd/system/

# Restart everything
for i in stop enable status start status ; do
  date | tee -a $LOGFILE
  sudo systemctl ${i} prometheus.service  | tee -a $LOGFILE
done


exit 0

