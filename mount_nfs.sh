#!/bin/bash
# Ansible ad hoc commands to setup NFS mounts on clients
# Brute force - no error checking.

for i in $(seq 1 6); do
    #echo "ansible -i ./inventory clients -a \"mkdir /mount/nfs${i}\""
    ansible -i ./inventory clients -a "mkdir -p /mount/share${i}"
done

j=1
for i in $(seq 1 6); do
    #ansible -i ./inventory clients -a "mount -t nfs 10.100.7.${i}:/nfs${j} /mount/nfs${j}"
    ansible -i ./inventory clients -a "mount -o proto=tcp,vers=3,nconnect=8 mountvip.arrakis.org:/share${j} /mount/share${j}"
    ((j++))
done