#!/usr/bin/bash
###===============================================================================###
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
###===============================================================================###
#
#   Setup Charging Demo database and users
#     Modified by:
#     Karl Vietmeier - Intel Cloud CSA
#
#   From: https://github.com/srmadscience/voltdb-charglt
#
#   Run this before using the benchmraking scripts - it:
#    * Imports the Charging DB schema  
#    * Updates config.xml for "Topics Data" (do this up front)
#    * Adds Grafana dashboards
#    * Imports a bunch of data and creates 4M users
#
###===============================================================================###

# Don't really need this but what the heck
. $HOME/.profile

# Setup some Variables - 
USERCOUNT=4000000
DEMODIR=${HOME}/voltdb-charglt
JARDIR=${DEMODIR}/jars
DDLDIR=${DEMODIR}/ddl
SCRIPTDIR=${DEMODIR}/scripts
HOSTS=$(tr '\n' ',' < ${HOME}/.vdbhostnames | sed 's/,$//')


###--------- Shouldn't need to edit below this line ----------### 


# We need an output dir should have been created by setup.sh
if [ ! -d $HOME/logs ] ; then
  mkdir $HOME/logs 2> /dev/null
fi

echo ""
echo ""
echo "###"
echo "#==================================  Setting up Charging Demo   ==================================###"
echo "###"
echo ""
echo ""
sleep 5


###--- Functions
function import_schema () {
  # Setup Charging Demo schema
  
  echo ""
  echo "#============================= Import Schema =============================###"
  echo ""

  cd $DDLDIR
  echo "sqlcmd --servers=${HOSTS} < ${DDLDIR}/create_db.sql"
  sqlcmd --servers=${HOSTS} < ${DDLDIR}/create_db.sql
  echo ""

}

function reload_dboards () {
  # Setup Grafana Dashboards
  
  echo ""
  echo "###==================== Reload Grafana Dashboards ========================###"
  echo ""
  cd $SCRIPTDIR

  echo "${HOME}/bin/reload_dashboards.sh ${SCRIPTDIR}/ChargeLt.json"
  sudo ${HOME}/bin/reload_dashboards.sh ${SCRIPTDIR}/ChargeLt.json
  echo ""
  echo ""

}


function import_data () {
  # Populate the database?
  
  echo ""
  echo "###============================ Import Data ==============================###"
  echo ""
  
  cd $JARDIR

  echo "java ${JVMOPTS} -jar ${JARDIR}/CreateChargingDemoData.jar $HOSTS $USERCOUNT 30 100000"
  java ${JVMOPTS} -jar ${JARDIR}/CreateChargingDemoData.jar $HOSTS $USERCOUNT 30 100000
  echo ""

}


function update_xml () {
  # Adds "Topics" fix to deployment XML - needs to run on the db nodes
  # Not needed - putting it in the original init config file.
  
  echo ""
  echo "###======================= Update Deployment XML =========================###"
  echo ""

  echo "java  ${JVMOPTS}  -jar $HOME/bin/addtodeploymentdotxml.jar $HOSTS deployment ${SCRIPTDIR}/export_and_import.xml"
  java  ${JVMOPTS}  -jar $HOME/bin/addtodeploymentdotxml.jar $HOSTS deployment ${SCRIPTDIR}/export_and_import.xml
  echo ""

  for node in $(cat ${HOME}/.vdbhostnames)
    do
      # Need to test this one
      ssh $node "java ${JVMOPTS} -jar $HOME/bin/addtodeploymentdotxml.jar $HOSTS deployment ${SCRIPTDIR}/export_and_import.xml"
      sleep 5
    done

}


###--- Main - put a short pause to view output of each section
#update_xml
#sleep 3
reload_dboards
sleep 3
import_schema
sleep 3
import_data
sleep 3


echo ""
echo ""
echo ""
echo "#==================================     DONE    ===========================================###"
echo ""
echo ""
