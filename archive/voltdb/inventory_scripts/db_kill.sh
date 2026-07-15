#!/usr/bin/bash -x
# Kill the voltdb process but leave Prometheus exporters running 

num_nodes=6
inventory="${HOME}/ansible/volt/inventory_${num_nodes}node"

#ansible voltnodes -i ${inventory} voltnodes -m shell -a "ps -ef | grep voltdb | grep -v grep | grep -v voltdbprometheus | awk '{print \$2 }' | xargs kill"
ansible voltnodes -i ./inventory_6nodes voltnodes -m shell -a "ps -ef | grep voltdb | grep -v grep | grep -v voltdbprometheus | awk '{print \$2 }' | xargs kill"
