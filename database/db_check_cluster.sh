#!/usr/bin/bash
# Check cluster status
ansible vdb-01 -m shell -a "echo \"exec @SystemInformation overview;\" | /home/ubuntu/voltdb-ent-11.4/bin/sqlcmd --servers=vdb-02 | grep HOSTNAME | awk '{ print $3 }' | sort"
