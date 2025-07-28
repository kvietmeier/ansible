#!/bin/bash
# ====================================================================
# NFS Share Setup and Elbencho Test Automation Script
#
# Description:
#   Automates NFS client setup, mount operations, and elbencho testing
#   across multiple clients using Ansible ad hoc commands.
#
# Usage:
#   ./nfs_test.sh <action> [NUM_CLIENTS] [NUM_SHARES]
#
# Actions:
#   mountall          - Ensure mount points exist for all shares (round-robin per client)
#   elbencho_mixed    - Run elbencho with mixed random read/write workload
#   elbencho_seq      - Run elbencho with sequential write workload
#   parse_results     - Parse /tmp/elbencho_write.log from each client
#
# Example:
# ./your_script.sh mkdirs 11 11
# ./your_script.sh mount 11 11
# ./your_script.sh elbencho_mixed 11 11
# or:
# ./your_script.sh elbencho_seq 11 11
#
#
# Defaults:
#   NUM_CLIENTS = 8
#   NUM_SHARES  = 8
#
# Notes:
#   - Assumes hosts named client01, client02, ..., client0n in inventory
#   - Inventory file is expected at ./inventory - with hosts defined as client01, client02, etc.
#   - Elbencho must be installed on all clients
#   - Elbencho server will run in the background on each client
#   - Elbencho prep will create files for testing
#   - Elbencho results will be stored in /tmp/elbencho_write.log on each client
#   - Elbencho prep will create /mount/share1/elbencho-files
#   - Elbencho mixed test will run with various block sizes and workloads
#   - Elbencho sequential write test will run with a 100G file size
#   - Elbencho results stored in /tmp/elbencho*.log on each client
# ====================================================================

# Positional parameters
NUM_CLIENTS=${2:-11}
NUM_SHARES=${3:-8}

#port_range="33.20.1.11-33.20.1.21"
port_range="33.20.1.11-33.20.1.13"
DNS_ALIAS="sharespool"
DNS="busab"
#view_path="nfs_share_"
view_path="nfs_share_1"
conns="11"

function mount_all () {
  for i in $(seq 1 $NUM_CLIENTS); do
    client=$(printf "client%02d" "$i")
    #echo "Mounting /share${i} and creating elbencho-files directory on $client..."
    echo "Mounting /share1 and creating elbencho-files directory on $client..."
    #echo  "mount -t nfs -o proto=tcp,vers=3,nconnect=${conns},remoteports=${port_range} ${DNS_ALIAS}.${DNS}.org:/${view_path}${i} /mount/share1"
    echo  "mount -t nfs -o proto=tcp,vers=3,nconnect=${conns},remoteports=${port_range} ${DNS_ALIAS}.${DNS}.org:/${view_path} /mount/share1"
    ansible -i ./inventory "$client" -a "mount -t nfs -o proto=tcp,vers=3,nconnect=${conns},remoteports=${port_range} ${DNS_ALIAS}.${DNS}.org:/${view_path} /mount/share1"
    ansible -i ./inventory "$client" -m shell -a "mkdir -p /mount/share1/elbencho-files"
    ansible -i ./inventory "$client" -m shell -a "chmod 777 /mount/share1/elbencho-files"
  done
}

# Function to run elbencho server on all clients
# This function starts the elbencho server in the background on each client
# It assumes that elbencho is installed and available in the PATH on each client.
# It also assumes that the elbencho server can be started with the command `elbencho
# Check it is running
#  ansible -i ./inventory clients -m shell -a "ps -ef | grep elbencho"
function run_elbencho_server () {
  for i in $(seq 1 $NUM_CLIENTS); do
    client=$(printf "client%02d" "$i")
    echo "Starting elbencho server on $client" 
    ansible -i ./inventory "$client" -m shell -a "nohup elbencho --service"
  done
}  

function copy_elbencho_prep_script () {
  echo "Copying static elbencho prep script to client01..."

  ansible -i ./inventory client01 -m copy -a \
    "src=./files/elbencho_test_block_sizes.sh dest=/home/labuser/elbencho_prep.sh mode=0755 owner=labuser group=labuser"
}

function copy_elbencho_block_test_script () {
  echo "Copying static elbencho block size test script to client01..."

  ansible -i ./inventory client01 -m copy -a \
    "src=./files/elbencho_test_block_sizes.sh dest=/home/labuser/elbencho_test_block_sizes.sh mode=0755 owner=labuser group=labuser"
}




###==============================================================================###  

# Function to run elbencho prep on client01
# This function prepares the elbencho environment by creating files for testing
function run_elbencho_prep () {
  echo "Starting elbencho prep on client01/share1..."
  ansible -i ./inventory client01 -m shell -a \
    "elbencho --hosts client[01-{{ NUM_CLIENTS }}] -t 32 --iodepth 4 -b 1M --direct -s 10G -w /mount/share1/elbencho-files/file[1-10] --csvfile /tmp/elbenchoprep.csv > /tmp/elbencho.log 2>&1" -e "NUM_CLIENTS=$NUM_CLIENTS" 
}

function run_elbencho_prepa () {
  echo "Generating elbencho prep command file on client01..."

  local cmd="elbencho --hosts client[01-${NUM_CLIENTS}] -t 32 --iodepth 4 -b 1M --direct -s 10G -w /mount/share1/elbencho-files/file[1-10] --csvfile /tmp/elbenchoprep.csv > /tmp/elbencho.log 2>&1"

  ansible -i ./inventory client01 -m copy -a "content='$cmd' dest=/home/labuser/elbencho_prep_cmd.sh mode=0755 owner=labuser group=labuser"
}

function run_elbencho_blksizes_cmd_file () {
  echo "Generating elbencho blocksize commands file on client01..."

  local cmds=""
  for testcase in "--read --rand" "--read" "--write --rand" "--write"; do
    for blocksize in 4k 8k 16k 32k 64k 128k 256k 512k 1m 2m; do
      cmds+="elbencho --hosts client[01-${NUM_CLIENTS}] $testcase --block $blocksize --size 10g --direct -t 32 --iodepth 4 --nofdsharing --infloop --timelimit 5 --resfile /tmp/results.txt --csvfile /tmp/results.csv /mount/share1/elbencho-files/file[1-10]\n"
    done
  done

  # Use ansible copy module to write the content to the remote file
  # Note: We need to handle newline chars properly. Use printf and base64 to avoid quoting issues

  # Encode commands as base64
  local cmds_b64=$(printf "%b" "$cmds" | base64 -w0)

  ansible -i ./inventory client01 -m shell -a "echo $cmds_b64 | base64 -d > /home/labuser/elbencho_blks_cmds.sh && chmod 755 /home/labuser/elbencho_blks_cmds.sh"
}






# Main entry point
case "$1" in
  mkdirs)
    mkdirs
    ;;
  mount)
    mount_all
    ;;
  elbencho_prepare)
    gen_elbencho_prep_cmds
    ;;
  elbencho_runblks)
    gen_elbencho_blksize_cmds
    ;;
  elbencho_serv)
    run_elbencho_server
    ;;
  elbencho_prep)
    run_elbencho_prep
    ;;
  elbencho_blks)
    run_elbencho_blksizes
    ;;
  copy_blk)
    copy_elbencho_block_test_script
    ;;
  parse_results)
    parse_elbencho_results
    ;;
  kill_elbencho)
    kill_elbencho_server
    ;;
  *)
    echo "Usage: $0 {mkdirs|mount|elbencho_prep|elbencho_serv|elbencho_blks|elbencho_seq|parse_results|kill_elbencho} [NUM_CLIENTS] [NUM_SHARES]"
    exit 1
    ;;
esac
