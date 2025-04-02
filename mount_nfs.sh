#!/bin/bash
# Ansible ad hoc commands to setup NFS mounts on clients
3 Brute force - no error checking.

for i in $(seq 1 6); do
    #echo "ansible -i ./inventory clients -a \"mkdir /mount/nfs${i}\""
    ansible -i ./inventory clients -a "mkdir /mount/nfs${i}"
done

j=1
for i in $(seq 80 85); do
    ansible -i ./inventory clients -a "mount -t nfs 10.100.2.${i}:/nfs${j} /mount/nfs${j}"
    ((j++))
done
