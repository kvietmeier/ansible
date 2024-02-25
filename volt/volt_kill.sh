#!/usr/bin/bash
# Kill volt stats exporter if it is running

inventory="${HOME}/ansible/inventory"

ansible voltnodes -i $inventory -m shell -a "ps -ef | grep voltdb | grep -v grep | grep -v voltdbprometheusbl | awk '{print \$2 }' | xargs kill"
