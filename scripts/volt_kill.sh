#!/usr/bin/bash
# Kill volt if it is running

ansible voltnodes -m shell -a "ps -ef | grep voltdb | grep -v grep | grep -v voltdbprometheusbl | awk '{print \$2 }' | xargs kill"
