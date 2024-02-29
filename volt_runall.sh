#!/usr/bin/bash
# Written by: Karl Vietmeier
#
# Use: Wrapper for setting up VoltDB - equivalent to "voltwrangler" on AWS
#
# Node list is set in $volt_nodes (source a file instead?)
# Mgmt node is vdb-01
#
# NOTE: "~" gets passed as a string, "$HOME" gets interepted locally - then passed
#

###---- Vars
num_nodes=3
volt_ver=11.4
volt_user=ubuntu
playbook=${HOME}/ansible/roles/voltdb/voltdb.yaml
volt_bin="/home/ubuntu/voltdb-ent-${volt_ver}/bin/voltdb"
demo_dir="/home/ubuntu/chargingdb"
bmark_dir="/home/ubuntu/voltdb-charglt/scripts/"
demo_file="/home/ubuntu/demo_cluster_config.xml"
license_file="/home/ubuntu/license.xml"
start_cmd="nohup $volt_bin start --dir=${demo_dir} --host=${volt_host} > $HOME/voltstart.out 2> $HOME/voltstart.err < /dev/null &"

# Reference a list of DB nodes
#db_hosts_file=${HOME}/ansible/vdbhosts.txt            # Has list of DB nodes

# Might not need these - trying not to hard code stuff in the script
volt_db_nodes=("vdb-02" "vdb-03" "vdb-04" "vdb-05")   # Array of DB Nodes
volt_hosts=$(IFS=,; echo "${volt_nodes[*]}")

# Check for different numbers of nodes
if [ $num_nodes -eq 3 ] ; then
  inventory=${HOME}/ansible/volt/inventory_3node
  db_hosts_file=${HOME}/ansible/volt/vdb3hosts.txt            # Has list of DB nodes
fi
if [ $num_nodes -eq 6 ] ; then
  inventory=${HOME}/ansible/volt/inventory_6node
  db_hosts_file=${HOME}/ansible/volt/vdb6hosts.txt            # Has list of DB nodes
fi
if [ $num_nodes -eq 9 ] ; then
  inventory=${HOME}/ansible/volt/inventory_9node
  db_hosts_file=${HOME}/ansible/volt/vdb9hosts.txt            # Has list of DB nodes
fi

servers=$(tr '\n' ',' < $db_hosts_file | sed 's/,$//')

###=========================================================================================###
###                        Shouldn't need to edit below this line                           ###


###=========================================================================================###
#    Functions - 
###=========================================================================================###

function playbooks () {
  # Using tags in Playbook to break up tasks for hosts.
  echo ""
  echo "###=========================================###"
  echo "    Running Database Node Playbook"
  echo "###=========================================###"
  echo ""

  ansible-playbook --limit voltnodes -i $inventory $playbook --tags=apt,system,userenv,volt_env,git,ssh_setup,copy_files,voltdb_setup
  
  sleep 5

  # Setup mgmt host
  echo ""
  echo "###=========================================###"
  echo "    Running Management Node Playbook"
  echo "###=========================================###"
  echo ""

  ansible-playbook --limit voltmgmt -i $inventory $playbook --tags=apt,system,userenv,volt_env,git,ssh_setup,copy_files
  sleep 2

  ansible-playbook --limit voltmgmt -i $inventory $playbook --tags=mgmt_host
  sleep 5
}


function init () {
  # Initialize database
  echo ""
  echo "###=========================================###"
  echo "    Initializing Databases"
  echo "###=========================================###"
  echo ""
  
  echo ansible voltnodes -i $inventory -m shell -a "$volt_bin init --dir=$demo_dir --config=$demo_file --license=$license_file --force" --become-user $volt_user
  ansible voltnodes -i $inventory -m shell -a "$volt_bin init --dir=$demo_dir --config=$demo_file --license=$license_file --force" --become-user $volt_user
}


function start_volt () {
  # Start DB nodes in sequence with Ansible
  # This does not check for already running instances
  echo ""
  echo "###=========================================###"
  echo "    Starting Databases"
  echo "###=========================================###"
  echo ""

  for node in $(cat $db_hosts_file) ; do	 
    # This works - need both nohup and move & to the end
    # Works equally as well as a straight SSH pass through

    echo ansible $node -i $inventory -m shell -a "nohup $volt_bin start --dir=$demo_dir --host=$servers > ~/voltstart.out 2> ~/voltstart.err < /dev/null &" --become-user $volt_user
    ansible $node -i $inventory -m shell -a "nohup $volt_bin start --dir=$demo_dir --host=$servers > ~/voltstart.out 2> ~/voltstart.err < /dev/null &" --become-user $volt_user
    sleep 10
  done

  # ToDo - Run setup.sh

}

function prometheus_dbstats_export () { 
  echo ""
  echo "###=========================================###"
  echo "    Configure Prometheus DB stats"
  echo "###=========================================###"
  echo ""

  for node in $(cat $db_hosts_file) ; do	 
    # Need to setup export of stats on each DB node
    ansible $node -i $inventory -m shell -a "~/bin/voltdbprometheusbl_start.sh 2> ~/voltprometheusbl.err < /dev/null &"
    sleep 3
  done

}


function run_demo_setup () {
  echo ""
  echo "###=========================================###"
  echo "    Run setup.sh script for Demo benchmarks"
  echo "###=========================================###"
  echo ""
  
  ansible voltmgmt -i $inventory -m shell -a "${bmark_dir}/setup.sh" --become-user $volt_user
  
}


###=======================================================================================###
#    Main - 
###=======================================================================================###

# Call the functions - comment/uncomment as needed
playbooks
#init
#start_volt
#prometheus_dbstats_export
#run_demo_setup
