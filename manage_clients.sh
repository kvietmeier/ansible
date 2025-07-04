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
#   mkdirs            - Create /mount/shareX directories on all clients
#   mountall          - Ensure mount points exist for all shares (round-robin per client)
#   mount             - Mount NFS shares on each client (round-robin)
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
#   - Assumes hosts named linux01, linux02, ..., linux08 in inventory
#   - Inventory file is expected at ./inventory
#   - Elbencho results stored in /tmp/elbencho*.log on each client
# ====================================================================

# Positional parameters
NUM_CLIENTS=${2:-8}
NUM_SHARES=${3:-8}

port_range="33.20.1.11-33.20.1.21"
DNS_ALIAS="sharespool"
DNS="busab"
view_path="nfs_share_"
conns="11"
#mount -o 

function mkdirs () {
  for i in $(seq 1 $NUM_CLIENTS); do
    client=$(printf "client%02d" "$i")
    echo "Creating /mount/share${i} on $client..."
    ansible -i ./inventory all -l "$client" -a "mkdir -p /mount/share${i}"
  done
}

function mount_all () {
  for i in $(seq 1 $NUM_CLIENTS); do
    client=$(printf "client%02d" "$i")
    echo "Mounting /share${i} and creating elbencho-files directory on $client..."
    echo  "mount -t nfs -o proto=tcp,vers=3,nconnect=${conns},remoteports=${port_range} ${DNS_ALIAS}.${DNS}.org:/${view_path}${i} /mount/share${i}"
    #ansible -i ./inventory "$client" -a \
    #  "mount -t nfs -o proto=tcp,vers=3,nconnect=${conns},remoteports=${port_range} ${DNS_ALIAS}.${DNS}.org:/${view_path}${i} /mount/share${i}"
    #ansible -i ./inventory "$client" -m shell -a "mkdir -p /mount/share${i}/elbencho-files"
    ansible -i ./inventory "$client" -m shell -a "chmod 777 /mount/share${i}/elbencho-files"
  done
}

function run_elbencho_mixed () {
  for i in $(seq 1 $NUM_CLIENTS); do
    client=$(printf "client%02d" "$i")
    echo "Starting elbencho (mixed) on $client (share${i})..."
    ansible -i ./inventory "$client" -m shell -a \
      "nohup elbencho -d -t 2 --iodepth 4 --timelimit 2400 -b 1M --direct -s 100G -N 1000 -n 10 -D -F -d -w --rand /mount/share${i}/elbencho-files > /tmp/elbencho.log 2>&1 &" &
  done
  wait
  echo "Mixed elbencho test started on all clients."
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

# Main entry point
case "$1" in
  mkdirs)
    mkdirs
    ;;
  mount)
    mount_all
    ;;
  elbencho_mixed)
    run_elbencho_mixed
    ;;
  elbencho_seq)
    run_elbencho_seq
    ;;
  parse_results)
    parse_elbencho_results
    ;;
  *)
    echo "Usage: $0 {mkdirs|mount|elbencho_mixed|elbencho_seq|parse_results} [NUM_CLIENTS] [NUM_SHARES]"
    exit 1
    ;;
esac
