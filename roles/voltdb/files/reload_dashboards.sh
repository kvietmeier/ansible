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

###=======================================================================================###
#   Modified for Azure by:
#        Karl Vietmeier - Intel Cloud CSA
#
#   Called from the Charging Demo setup.sh script - resets the Dashboards to 0.
#   
#   Usage:  reload_dashboards.sh /home/ubuntu/voltdb-charglt/scripts/ChargeLt.json
#
###=======================================================================================###


# Setup the Grafana dashboards for the benchmarks
etc_dash_dir="/etc/dashboards"
volt_dash_dir="${HOME}/bin/dashboards"

# Stop Grafana
sudo systemctl stop grafana-server

# Were we called from the Charging Demo setup script
# If so - copy the Charging Demo dashboards to the Volt bin_dir
if [ "$1" != "" ] ; then
  cp $1 $volt_dash_dir
fi

# Does /etc/dashboards exist?
if [ ! -d $etc_dash_dir ] ; then
  sudo mkdir $etc_dash_dir 2> /dev/null

else
  # Clean out the directory if it exists
  cd $etc_dash_dir
  sudo ls -A | xargs rm -rf
fi

# Now copy over the new dashboards to the system dir
sudo cp -r  ${volt_dash_dir}/* $etc_dash_dir

# Update group ownership
sudo find $etc_dash_dir -exec chgrp grafana {} \;


# Start Grafana back up with new dashboards
sudo systemctl daemon-reload
sudo systemctl start grafana-server