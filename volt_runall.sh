#!/usr/bin/bash
# Written by: Karl Vietmeier
#
# Use: Wrapper for setting up VoltDB
#
# Node list is set in $volt_nodes (source a file instead?)
# Mgmt node is vdb-01
#
# NOTE: "~" gets passed as a string, "$HOME" gets interepted locally - then passed
#

###---- Vars
inventory=${HOME}/ansible/inventory
playbook=${HOME}/ansible/roles/voltdb/voltdb.yaml
volt_ver=11.4
volt_user=ubuntu
volt_bin="/home/ubuntu/voltdb-ent-${volt_ver}/bin/voltdb"
demo_dir="/home/ubuntu/chargingdb"
config_file="/home/ubuntu/demo_cluster_config.xml"
license_file="/home/ubuntu/license.xml"
start_cmd="nohup $volt_bin start --dir=${demo_dir} --host=${volt_host} > $HOME/voltstart.out 2> $HOME/voltstart.err < /dev/null &"
volt_nodes=("vdb-02" "vdb-03" "vdb-04" "vdb-05")

###=============================== Should not need to edit below this line ====================================###


###---- Functions
# Using tags in Playbook to break up tasksd for hosts.
function playbooks () {
  echo ""
  echo "###====================================###"
  echo "    Running Database Node Playbook"
  echo "###====================================###"
  echo ""
  # First step - install binaries etc.
  ansible-playbook --limit voltnodes -i $inventory $playbook --tags=apt,system,userenv,git,ssh_setup,copy_files,voltdb_setup
  sleep 5

  # Setup mgmt host
  echo ""
  echo "###====================================###"
  echo "    Running Management Node Playbook"
  echo "###====================================###"
  echo ""
  ansible-playbook --limit voltmgmt -i $inventory $playbook --tags=apt,system,userenv,git,ssh_setup,copy_files
  sleep 2
  ansible-playbook --limit voltmgmt -i $inventory $playbook --tags=mgmt_host
  sleep 5
}

function init () {
  # Initialize database
  echo ""
  echo "###====================================###"
  echo "    Initializing Databases"
  echo "###====================================###"
  echo ""
  ansible voltnodes -i $inventory -m shell -a "$volt_bin init --dir=$demo_dir --config=$demo_file --license=$license_file --force" --become-user $volt_user
}

sleep 10

function start_volt () {
  # Start DB nodes in sequence with Ansible
  # This does not check for already running instances
  echo ""
  echo "###====================================###"
  echo "    Starting Databases"
  echo "###====================================###"
  echo ""

  for node in ${volt_nodes[@]} ; do	 
    # This works - need both nohup and move & to the end
    # Works equally as well as a straight SSH pass through
    ansible $node -m shell -a "nohup $volt_bin start --dir=$demo_dir --host=$volt_hosts > ~/voltstart.out 2> ~/voltstart.err < /dev/null &" --become-user $volt_user
    sleep 10
  done


  # ToDo - Run setup.sh
  # Add the Prometheus java

}

function setup_prometheus_export () {

  for node in ${volt_nodes[@]} ; do	 
    # Need to setup export of stats on each DB node
    ansible $node -m shell -a "~/bin/voltdbprometheusbl_start.sh 2> ~/voltprometheusbl.err < /dev/null &" --become-user $volt_user
    sleep 3
  done

}



###---- END Functions


# Call functions
#playbooks
#init
#start_volt
setup_prometheus_export
