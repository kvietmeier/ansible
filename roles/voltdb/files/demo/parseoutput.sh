#!/usr/bin/bash
###=======================================================================================###
#   Modified for Azure by:
#        Karl Vietmeier - Intel Cloud CSA
#
#   Gather output from benchmark runs and format it for graphing.
#   This is tied to the voltwrangler script - it uses the "params" file
#
#   Usage:
#     gatherstats.sh TestName outputfile.out
#
#     TestName = vCPUs/Instance
#     output_file = test results output
#
#   Not using voltwrangler - need to source the params elsewhere.
#   - Most of the info added isn't particularly useful on each line.
#
#
###=======================================================================================###

###---- Input vars
TNAME=$1
test_output=$2

###---- Set some variables
# Azure API endpoint to get VM instance type and OS SKU
AzureAPI="http://169.254.169.254/metadata/instance/compute?api-version=2021-02-01"

# Grab VM info
VMSize=$(curl -s -H Metadata:true --noproxy "*" "$AzureAPI" | jq | grep -i vmsize | awk -F "\"" '{print $4}')
OS_SKU=$(curl -s -H Metadata:true --noproxy "*" "$AzureAPI" | jq | grep -m 1 -i sku | awk -F "\"" '{print $4}')
CPU_SKU=$(sudo dmidecode -t 4 | egrep -i 'Version' | awk '{print $5}')
CPU_ghz=$(sudo dmidecode -t 4 | egrep -i 'Version' | awk '{print $8}')

# Cluster info -
# ToDo - grab this from somewhere else, for now, hard code it.
KFACTOR=1
CMDLOGGING="Yes"
DEMONAME="ChargingDemo"
SPH=3
NODECOUNT=4

# Don't need this.
#echo -n SKU:TESTNAME:INSTANCE:KFACTOR:CMDLOGGING:DEMONAME:SPH:NODECOUNT:FILE:DATE:TIME_MINS:TIME_SS:GREP:TARGET_TPMS:ACTUAL_TPS:

# Create headings for data columns
for i in RQU KV_GET KV_PUT ; do
  for j in AVG 50 99 99.9 99.99 99.999 MAX MAX_FREQ ; do
   echo -n ${i}_${j}:
  done
done

echo ""

# Generate output file with metadata about test prepended
grep GREPABLE $test_output | sed '1,$s/^/'${TNAME},${VMSize},${CPU_SKU},${CPU_ghz},${OS_SKU},${DEMONAME},${CMDLOGGING},${SPH},${NODECOUNT},$test_output,'/g'

~