#!/usr/bin/bash
# Written by: Karl Vietmeier
#
# Use: Wrapper for setting up VoltDB
#
# Hard coded for 4 nodes+mgmt node.

###---- Vars
inventory=${HOME}/ansible/inventory
playbook=${HOME}/ansible/roles/voltdb/voltdb.yaml
volt_ver=11.4
volt_user=ubuntu
volt_bin="/home/ubuntu/voltdb-ent-${volt_ver}/bin/voltdb"
demo_dir="/home/ubuntu/chargingdb"
start_cmd="nohup $volt_bin start --dir=${demo_dir} --host=${volt_host} > $HOME/voltstart.out 2> $HOME/voltstart.err < /dev/null &"
volt_host="vdb-02,vdb-03,vdb-04,vdb-05"

###---- Functions
function playbooks () {
  # First step - install binaries etc.
  ansible-playbook --limit voltnodes -i $inventory $playbook
  sleep 5

  # Setup mgmt host
  ansible-playbook --limit voltmgmt $playbook --tags=git,apt,system,userenv,copy_files
  sleep 5
}

function init () {
  # Initialize database
  ansible voltnodes -i $inventory -m shell -a "/home/ubuntu/voltdb-ent-${volt_ver}/bin/voltdb init --dir=~/chargingdb --config=~/demo_cluster_config.xml --license=~/license.xml --force" --become-user ubuntu
}

sleep 10

function start_volt () {
  # Start DB nodes in sequence with Ansible
  # This does not check for already running instances

  for node in 2 3 4 5 ; do	 
    # This works - need both nohup and move & to the end
    # Works equally as well as a straight SSH pass through
    ansible vdb-0${node} -m shell -a "nohup /home/ubuntu/voltdb-ent-${volt_ver}/bin/voltdb start --dir=/home/ubuntu/chargingdb --host=vdb-02,vdb-03,vdb-04,vdb-05 > $HOME/voltstart.out 2> $HOME/voltstart.err < /dev/null &"
    sleep 10
  done

}

###---- END Functions


# Call functions
playbooks
init
start_volt