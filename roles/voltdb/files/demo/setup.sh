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
#    * Imports a Charging DB schema  
#    * Creates 40K users
#    * Extends it somehow
#    * Importas a bunch of data
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

echo "#========================== Setting Up Charging Demo Environment ===========================###"
echo ""

# Setup Charging Demo schema
cd $DDLDIR
echo "Importing Charging Demo schema"
echo "sqlcmd --servers=${HOSTS} < ${DDLDIR}/create_db.sql"
sqlcmd --servers=${HOSTS} < ${DDLDIR}/create_db.sql
echo ""

# What is the JSON for?  It isn't in the README
cd ${SCRIPTDIR}
echo "${HOME}/bin/reload_dashboards.sh ${SCRIPTDIR}/ChargeLt.json"
${HOME}/bin/reload_dashboards.sh ${SCRIPTDIR}/ChargeLt.json
echo ""


# What does this do?
echo "java  ${JVMOPTS}  -jar $HOME/bin/addtodeploymentdotxml.jar $HOSTS deployment ${SCRIPTDIR}/export_and_import.xml"
java  ${JVMOPTS}  -jar $HOME/bin/addtodeploymentdotxml.jar $HOSTS deployment ${SCRIPTDIR}/export_and_import.xml
echo ""


# Populate the database?
cd $JARDIR
echo "Populating the database"
echo "java ${JVMOPTS} -jar ${JARDIR}/CreateChargingDemoData.jar $HOSTS $USERCOUNT 30 100000"
java ${JVMOPTS} -jar ${JARDIR}/CreateChargingDemoData.jar $HOSTS $USERCOUNT 30 100000
echo ""


echo ""
echo "#==================================     DONE    ===========================================###"
echo ""
