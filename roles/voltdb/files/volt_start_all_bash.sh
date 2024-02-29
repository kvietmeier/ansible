#!/usr/bin/bash
# Start DB nodes in sequence with Ansible
# This does not check for already running instances

volt_ver=11.4
volt_user=ubuntu
volt_hosts="vdb-02,vdb-03,vdb-04"
volt_bin="/home/ubuntu/voltdb-ent-${volt_ver}/bin/voltdb"
demo_dir="/home/ubuntu/chargingdb"
start_cmd="nohup $volt_bin start --dir=${demo_dir} --host=${volt_host} > $HOME/voltstart.out 2> $HOME/voltstart.err < /dev/null &"


for node in 2 3 4
 do
   # This works - need both nohup and move & to the end
   # Works equally as well as a straight SSH pass through

   # Need to test this one
   #ssh ${volt_user}@vdb-0${node}  "nohup $volt_bin  start --dir=${demo_dir} --host=${volt_hosts} > $HOME/voltstart.out 2> $HOME/voltstart.err < /dev/null &"
   
   # This works 
   ssh vdb-0${node}  "nohup /home/ubuntu/voltdb-ent-${volt_ver}/bin/voltdb start --dir=/home/ubuntu/chargingdb --host=vdb-02,vdb-03,vdb-04 > $HOME/voltstart.out 2> $HOME/voltstart.err < /dev/null &"
   sleep 10
 done