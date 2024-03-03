#!/usr/bin/bash
#
#  Gather output from benchmark runs and format it for graphing.
#  This is tied to the voltwrangler script - it uses the "params" file
#
#  Usage:
#  gatherstats.sh $1 $2 $3
#
###=======================================================================================###
#   Modified for Azure by:
#        Karl Vietmeier - Intel Cloud CSA
# 
#   Not using voltwrangler - need to source the params elsewhere.
#
###=======================================================================================###

### USE parseoutput.sh  ###


###---- Input vars
TNAME=$1
AMI=$2

###---- Set some variables
# Azure API endpoint
AzureAPI="http://169.254.169.254/metadata/instance/compute?api-version=2021-02-01"

# Grab VM info
VMSize=$(curl -s -H Metadata:true --noproxy "*" "$AzureAPI" | jq | grep -i vmsize | awk -F "\"" '{print $4}')
SKU=$(curl -s -H Metadata:true --noproxy "*" "$AzureAPI" | jq | grep -m 1 -i sku | awk -F "\"" '{print $4}')

# Cluster info - sourced from voltwrangler parms file
KFACTOR=$(cat $HOME/voltwrangler_params.dat | awk '{ print $2 }')
CMDLOGGING=$(cat $HOME/voltwrangler_params.dat | awk '{ print $3 }')
DEMONAME=$(cat $HOME/voltwrangler_params.dat | awk '{ print $5 }')
SPH=$(cat $HOME/voltwrangler_params.dat | awk '{ print $7 }')
NODECOUNT=$(cat $HOME/voltwrangler_params.dat | awk '{ print $10 }')

echo -n SKU:TESTNAME:INSTANCE:KFACTOR:CMDLOGGING:DEMONAME:SPH:NODECOUNT:FILE:DATE:TIME_MINS:TIME_SS:GREP:TARGET_TPMS:ACTUAL_TPS:

for i in RQU KV_GET KV_PUT ; do
  for j in AVG 50 99 99.9 99.99 99.999 MAX MAX_FREQ ; do
   echo -n ${i}_${j}:
  done
done

echo ""

grep GREPABLE $3 | sed '1,$s/^/'${sku}:${TNAME}:${VMSize}:${KFACTOR}:${CMDLOGGING}:${DEMONAME}:${SPH}:${NODECOUNT}:$3:'/g'

