#!/usr/bin/bash
# Start DB nodes in sequence with Ansible
# This does not check for already running instances

volt_ver=11.4
volt_user=ubuntu
volt_host="vdb-02,vdb-03,vdb-04,vdb-05"
volt_bin="/home/ubuntu/voltdb-ent-${volt_ver}/bin/voltdb"
demo_dir="/home/ubuntu/chargingdb"
start_cmd="nohup $volt_bin start --dir=${demo_dir} --host=${volt_host} > $HOME/voltstart.out 2> $HOME/voltstart.err < /dev/null &"


for node in 2 3 4 5
 do	 
   # This works - need both nohup and move & to the end
   # Works equally as well as a straight SSH pass through
   
   # Need to test this one
   #ansible vdb-0${node} -m shell -a $start_cmd
   ansible vdb-0${node} -m shell -a "nohup /home/ubuntu/voltdb-ent-${volt_ver}/bin/voltdb start --dir=/home/ubuntu/chargingdb --host=vdb-02,vdb-03,vdb-04,vdb-05 > $HOME/voltstart.out 2> $HOME/voltstart.err < /dev/null &"
   sleep 10
 done
