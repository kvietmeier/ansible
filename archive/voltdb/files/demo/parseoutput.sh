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

if [[ "$#" -eq 0 ]] ; then
  echo "You need to provide input values"
  echo "usage: ./parseoutput.sh <testname> <input file>"
  echo "example: ./parseoutput.sh Standard_D16ds_v5 10.16.120-200.out"
  echo ""
  exit 1
fi



# ToDo - grab these 3 from somewhere else, for now, hard code it.
DB_node="vdb-02"
KFACTOR=1
CMDLOGGING="Yes"
DEMONAME="ChargingDemo"

# Azure API endpoint to get VM instance type and OS SKU
AzureAPI="http://169.254.169.254/metadata/instance/compute?api-version=2021-02-01"

# Grab VM info from DB node
# ssh -i ~/.ssh/vdb-mgmt_priv ubuntu@vdb-02 (run command)
SSH_args=" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=QUIET"
Instance=$(ssh $SSH_args $DB_node -i ~/.ssh/vdb-mgmt_priv curl -s -H Metadata:true --noproxy "*" "$AzureAPI" | jq | grep -i vmsize | awk -F "\"" '{print $4}')
OS_SKU=$(ssh $SSH_args $DB_node -i ~/.ssh/vdb-mgmt_priv curl -s -H Metadata:true --noproxy "*" "$AzureAPI" | jq | grep -m 1 -i sku | awk -F "\"" '{print $4}')
CPU_SKU=$(ssh $SSH_args $DB_node -i ~/.ssh/vdb-mgmt_priv lscpu | egrep 'Model name' | awk '{print $6}')
CPU_ghz=$(ssh $SSH_args $DB_node -i ~/.ssh/vdb-mgmt_priv lscpu | egrep 'Model name' | awk '{print $9}')

# Cluster info -
SPH=$(sqlcmd --servers=${DB_node} --query="exec @SystemInformation OVERVIEW;" | grep -i cputhreads | head -1 | awk '{print $3}')
NODECOUNT=$(sqlcmd --servers=${DB_node} --query="exec @SystemInformation OVERVIEW;" | grep -i fullclustersize | head -1 | awk '{print $3}')
Volt_Build=$(sqlcmd --servers=${DB_node} --query="exec @SystemInformation OVERVIEW;" | grep BUILDSTRING | head -1 | awk '{print $3}')

# Grab VM info - Hard code if needed
#Instance="Standard_E16bds_v5"
#OS_SKU="Ubuntu_20.04"
#CPU_SKU="8372C"
#CPU_ghz="2.8ghz"

#output_csv = ${test_output}.csv

###---- End vars

# Put test metadata at the top of the file - makes for fewer columns
cat <<EOF 
Demo Name,, $DEMONAME 
Testname,, $TNAME
VM Instance,, $Instance
OS Version,, $OS_SKU
Volt Build,, $Volt_Build
CPU SKU,, $CPU_SKU
Base Freq,, $CPU_ghz
Logging,, $CMDLOGGING
SPH,, $SPH
Node Count,, $NODECOUNT
Output File,, $test_output

EOF

# Create column headers
echo -n "Date_Time,Filler,Target_TPMS,Actual_TPMS,"

for i in RQU KV_GET KV_PUT ; do
  for j in AVG 50 99 99.9 99.99 99.999 MAX MAX_FREQ ; do
   echo -n ${i}_${j}, 
  done
done

echo ""

# Generate output file with metadata about test prepended
# Convert to csv - bit of a hack but it works. Relies on time being at a specific location
grep GREPABLE $test_output | sed '1,$s/./-/14' | sed '1,$s/./-/17' | sed 's/:/,/g' 

