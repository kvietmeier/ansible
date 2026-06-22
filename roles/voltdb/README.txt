This set of files/folders are the files and scripts I had to modify to get Volt runniong on Azure.

They are in the structure of an Ansible role.

The inventory_scripts folder has inventory files and wrappers for executing the 
ansible playbooks and ansible adhoc commands top start amd initialze the DB.
  These go in the $HOME/ansible folder

These scripts and playbooks are run after you build the infrastructure in Azure and apply the correct cloud_init file.

azureuser@linuxtools:~/ansible/roles/database$ tree -L 2
.
├── README.txt
├── database.yaml
├── database.yaml.bak
├── files
│   ├── aliases
│   ├── azureuser.code-workspace
│   ├── demo
│   ├── demo_cluster_config.xml
│   ├── deployment-default.xml
│   ├── export_and_import.xml
│   ├── extra_profile
│   ├── filesystem.sh
│   ├── hosts
│   ├── keys
│   ├── license.xml
│   ├── ntpfix.sh
│   ├── old_license.xml
│   ├── prometheus.old.service
│   ├── prometheus.service
│   ├── prometheus.yml
│   ├── prometheus_start.sh
│   ├── prometheus_stop.sh
│   ├── prometheusserver_configure.sh
│   ├── reinit_chargingdemo.sh
│   ├── reinit_voltdb.sh
│   ├── reload_dashboards.sh
│   ├── setup_graf-prom.sh
│   ├── setup_part_1.sh
│   ├── setup_part_2.sh
│   ├── setup_runoncepercluster.sh
│   ├── setup_voltdb.sh
│   ├── system
│   ├── vimrc
│   ├── volt_start_all_bash.sh
│   ├── voltdb_start.sh
│   ├── voltdb_stop.sh
│   ├── voltdbprometheus_start.sh
│   ├── voltdbprometheus_stop.sh
│   ├── voltdbprometheusbl_start.sh
│   ├── voltdbprometheusbl_stop.sh
│   ├── voltwrangler.sh
│   └── waituntilclustersizeisx.sh
├── handlers
├── inventory_scripts
│   ├── d16tests.tar.gz
│   ├── db_check_cluster.sh
│   ├── db_init.sh
│   ├── db_kill.sh
│   ├── db_playbook.sh
│   ├── db_setup_mgmt.sh
│   ├── db_start_all.sh
│   ├── inventory_3node
│   ├── inventory_6node
│   ├── inventory_9node
│   ├── vdb3hosts.txt
│   ├── vdb6hosts.txt
│   └── vdb9hosts.txt
├── tasks
└── vars

