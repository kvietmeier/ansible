#!/bin/bash
# ====================================================================
# NFS Share Setup and Elbencho Test Automation Script
#
# Description:
#   Prepares NFS clients, mounts shares, manages elbencho server, and
#   copies static elbencho scripts (prep + block tests) to client01.
#
# Usage:
#   ./elbencho_setup.sh <action> [NUM_CLIENTS] [NUM_SHARES]
#
# Actions:
#   mount          - Ensure mount points exist and create test dirs
#   elbencho_serv  - Start elbencho server on all clients
#   copy_prep      - Copy elbencho prep script to client01
#   copy_blk       - Copy elbencho block test script to client01
#   kill_elbencho  - Stop elbencho server on all clients
#
# Example:
#   ./elbencho_setup.sh mount 11 1
#   ./elbencho_setup.sh copy_prep
#   ./elbencho_setup.sh copy_blk
#   ./elbencho_setup.sh elbencho_serv 11
#
# Notes:
#   - Inventory file must define client01, client02, etc.
#   - Static scripts live under ./files/
#   - Run copied scripts manually on client01 (pass NUM_CLIENTS param)o
#
#
# How to Change PRIMARY_CLIENT
#   - To change the primary client, export PRIMARY_CLIENT before running the script
#      export PRIMARY_CLIENT=client02
#   - Or override it in the environment by passing a different value as the 3rd argument
#      ./elbencho_setup.sh mount 11 8 client02
#   - Or set at run time - 
#      PRIMARY_CLIENT="client02" ./elbencho_setup.sh copy_prep
#
# ====================================================================
#!/bin/bash
# ====================================================================
# NFS Share Setup and Elbencho Test Automation Script
#
# Description:
#   Prepares NFS clients, mounts shares, manages elbencho server, and
#   copies static elbencho scripts (prep + block tests) to primary client.
#
# Usage:
#   ./elbencho_setup.sh <action> [NUM_CLIENTS] [NUM_SHARES]
#
# Actions:
#   mkdirs         - Create mount directories on all clients
#   mount          - Ensure mount points exist and create test dirs
#   elbencho_serv  - Start elbencho server on all clients
#   copy_prep      - Copy elbencho prep script to primary client
#   copy_blk       - Copy elbencho block test script to primary client
#   kill_elbencho  - Stop elbencho server on all clients
#
# Example:
#   ./elbencho_setup.sh mount 11 1
#   ./elbencho_setup.sh copy_prep
#   ./elbencho_setup.sh copy_blk
#   ./elbencho_setup.sh elbencho_serv 11
#
# Notes:
#   - Run copied scripts manually on primary client (pass NUM_CLIENTS param)
#   - PRIMARY_CLIENT can be overridden via environment variable
#   - Ansible: Inventory file must define client01, client02, etc.
#   - Ansible: Static scripts live under ./files/
#   - Ansible: 
#     The copy commands use the Ansible variable {{ ansible_env.HOME }} to
#     dynamically resolve the remote user's home directory. This ensures
#     the scripts are copied to the correct home directory regardless of
#     which user runs the playbook or the remote host's configuration.
#
# ====================================================================

# Defaults (can be overridden by positional parameters)
NUM_CLIENTS=${2:-11}
NUM_SHARES=${3:-8}
PRIMARY_CLIENT=${PRIMARY_CLIENT:-client01}  # Can export PRIMARY_CLIENT or override in env

# NFS settings
PORT_RANGE="33.20.1.11-33.20.1.13"
DNS_ALIAS="sharespool"
DNS="busab"
VIEW_PATH="nfs_share_1"
CONNS="11"

# --------------------------------------------------------------------
# Functions
# --------------------------------------------------------------------

function mkdirs () {
  for i in $(seq 1 $NUM_CLIENTS); do
    client=$(printf "client%02d" "$i")
    echo "Creating /mount/share1 on $client..."
    ansible -i ./inventory all -l "$client" -a "mkdir -p /mount/share1"
    ansible -i ./inventory "$client" -m shell -a "chmod 777 /mount/share1/"
  done
}

function mount_all () {
  for i in $(seq 1 $NUM_CLIENTS); do
    CLIENT=$(printf "client%02d" "$i")
    echo "Mounting /share1 and creating elbencho-files directory on $CLIENT..."
    ansible -i ./inventory "$CLIENT" -a \
      "mount -t nfs -o proto=tcp,vers=3,nconnect=${CONNS},remoteports=${PORT_RANGE} \
      ${DNS_ALIAS}.${DNS}.org:/${VIEW_PATH} /mount/share1"
    ansible -i ./inventory "$CLIENT" -m shell -a "mkdir -p /mount/share1/elbencho-files"
    ansible -i ./inventory "$CLIENT" -m shell -a "chmod 777 /mount/share1/elbencho-files"
  done
}

function run_elbencho_server () {
  for i in $(seq 1 $NUM_CLIENTS); do
    CLIENT=$(printf "client%02d" "$i")
    echo "Starting elbencho server on $CLIENT"
    ansible -i ./inventory "$CLIENT" -m shell -a "nohup elbencho --service &"
  done
}

function copy_elbencho_prep_script () {
  echo "Copying static elbencho prep script to $PRIMARY_CLIENT..."
  ansible -i ./inventory "$PRIMARY_CLIENT" -m copy -a \
    "src=./files/elbencho_prep.sh dest='{{ ansible_env.HOME }}/elbencho_prep.sh' mode=0755 owner=labuser group=labuser"
}

function copy_elbencho_block_test_script () {
  echo "Copying static elbencho block size test script to $PRIMARY_CLIENT..."
  ansible -i ./inventory "$PRIMARY_CLIENT" -m copy -a \
    "src=./files/elbencho_testblk_sizes.sh dest='{{ ansible_env.HOME }}/elbencho_testblk_sizes.sh' mode=0755 owner=labuser group=labuser"
}

function kill_elbencho_server () {
  for i in $(seq 1 $NUM_CLIENTS); do
    CLIENT=$(printf "client%02d" "$i")
    echo "Killing elbencho server on $CLIENT"
    ansible -i ./inventory "$CLIENT" -m shell -a "elbencho --quit --hosts localhost"
  done
}

# --------------------------------------------------------------------
# Main
# --------------------------------------------------------------------
case "$1" in
  mkdirs)
    mkdirs
    ;;
  mount)
    mount_all
    ;;
  elbencho_serv)
    run_elbencho_server
    ;;
  copy_prep)
    copy_elbencho_prep_script
    ;;
  copy_blk)
    copy_elbencho_block_test_script
    ;;
  kill_all)
    kill_elbencho_server
    ;;
  *)
    echo "Usage: $0 {mkdirs|mount|elbencho_serv|copy_prep|copy_blk|kill_all} [NUM_CLIENTS] [NUM_SHARES]"
    exit 1
    ;;
esac
