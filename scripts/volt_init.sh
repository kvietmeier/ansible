#!/usr/bin/bash

volt_ver=11.4

# Initialize database
ansible voltnodes -i ${HOME}/ansible/inventory -m shell -a "/home/ubuntu/voltdb-ent-${volt_ver}/bin/voltdb init --dir=~/chargingdb --config=~/demo_cluster_config.xml --license=~/license.xml --force" --become-user ubuntu
