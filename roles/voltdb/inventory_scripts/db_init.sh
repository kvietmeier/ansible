#!/usr/bin/bash
# Initialize the DBnodes

volt_ver=11.4
inventory="${HOME}/ansible/inventory"

ansible voltnodes -i $inventory -m shell -a "/home/ubuntu/voltdb-ent-${volt_ver}/bin/voltdb init --dir=~/chargingdb --config=~/demo_cluster_config.xml --license=~/license.xml --force" --become-user ubuntu
