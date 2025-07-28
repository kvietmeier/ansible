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


### Working command to run elbencho with various block sizes and workloads
# Example: elbencho --hosts "client01,client02" --read --rand --block 4k --size 10g --direct -t 32 --iodepth 4 --nofdsharing --infloop --timelimit 5 --resfile /tmp
function run_elbencho_blksizes () {

  echo "Starting elbencho on client01..."
  for testcase in "--read --rand" "--read" "--write --rand" "--write"; do
     for blocksize in 4k 8k 16k 32k 64k 128k 256k 512k 1m 2m; do
        echo "=== TESTCASE: $testcase --- BLOCKSIZE: $blocksize";
        ansible -i ./inventory client01 -m shell -a \
           'elbencho --hosts "client0[1-9],client[10-11]" $testcase --block $blocksize --size 10g --direct -t 32 --iodepth 4 --nofdsharing --infloop --timelimit 5 --resfile /tmp/results.txt --csvfile /tmp/results.csv /mount/share1/elbencho-files/file[1-10]' \
           -e "NUM_CLIENTS=$NUM_CLIENTS" --become-user=labuser
      done 
  
  echo "Mixed elbencho test started on all clients."
  
  done;
}


function run_elbencho_seq () {
  for i in $(seq 1 $NUM_CLIENTS); do
    client=$(printf "client%02d" "$i")
    echo "Launching sequential write test on $client (share${i})..."
    ansible -i ./inventory "$client" -m shell -a \
      "nohup elbencho -d -t 2 --iodepth 4 --timelimit 2400 -b 4M --direct -s 100G -N 4 -n 2 -w /mount/share${i} > /home/labuser/output/elbencho_write.log 2>&1 &" -b --become-user=labuser &
  done
  wait
  echo "Sequential elbencho write test started on all clients."
}

function parse_elbencho_results () {
  echo "==== Elbencho Throughput Summary (MB/s) ===="
  total=0

  for i in $(seq 1 $NUM_CLIENTS); do
    client=$(printf "linux%02d" "$i")
    echo -n "$client: "
    rate=$(ansible -i ./inventory "$client" -m shell -a \
      "grep -i 'MB/s' /tmp/elbencho_write.log | tail -1" \
      | grep -oE '[0-9]+\.[0-9]+ MB/s' | grep -oE '[0-9]+\.[0-9]+')

    if [[ -n "$rate" ]]; then
      printf "%8.2f MB/s\n" "$rate"
      total=$(echo "$total + $rate" | bc)
    else
      echo "No data"
    fi
  done

  echo "--------------------------------------------"
  printf "TOTAL: %8.2f MB/s\n" "$total"
}

function kill_elbencho_server () {
  for i in $(seq 1 $NUM_CLIENTS); do
    client=$(printf "client%02d" "$i")
    echo "Killing elbencho server on $client" 
    ansible -i ./inventory "$client" -m shell -a "nohup elbencho --quit --hosts localhost"
  done
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
  elbencho_seq)
    run_elbencho_seq
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
