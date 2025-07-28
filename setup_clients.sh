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
#
# Example with 11 clients, one view:
# ./your_script.sh mkdirs 1 11
# ./your_script.sh mount 1 11
#
# Defaults:
#   NUM_CLIENTS = 3
#   NUM_SHARES  = 1
#
# Notes:
#   - Assumes hosts named linux01, linux02, ..., linux08 in inventory
#   - Inventory file is expected at ./inventory
# ====================================================================

###--- Positional parameters
# $2 = second argument passed to script
# $3 = third argument passed to script
NUM_CLIENTS=${2:-3}   # If $2 is unset or empty, use 3 as default
NUM_SHARES=${3:-1}     # If $3 is unset or empty, use 1 as default

###--- Variables
# VIP Pool
#port_range="33.20.1.11-33.20.1.21"
port_range="33.20.1.11-33.20.1.13"

# VAST DNS settings
DNS_ALIAS="sharespool"
DNS="busab"
#view_path="nfs_share_"
view_path="nfs_share_1"
conns="11"

function mkdirs () {
  for i in $(seq 1 $NUM_CLIENTS); do
    client=$(printf "client%02d" "$i")
    #echo "Creating /mount/share${i} on $client..."
    echo "Creating /mount/share1 on $client..."
    ansible -i ./inventory all -l "$client" -a "mkdir -p /mount/share1"
    ansible -i ./inventory "$client" -m shell -a "chmod 777 /mount/share1/"
  done
}

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


# Main entry point
case "$1" in
  mkdirs)
    mkdirs
    ;;
  mount)
    mount_all
    ;;
  *)
    echo "Usage: $0 {mkdirs|mount} [NUM_CLIENTS] [NUM_SHARES]"
    echo "Example: $0 mkdirs 11 11"
    exit 1
    ;;
esac
