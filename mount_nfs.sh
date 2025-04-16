#!/bin/bash
# Ansible ad hoc commands to setup NFS mounts on clients
# Brute force - no error checking.

#for i in $(seq 1 6); do
#    echo "ansible -i ./inventory clients -a \"mkdir -p /mount/share${i}\""
#    ansible -i ./inventory clients -a "mkdir -p /mount/share${i}"
#done

j=1
for i in $(seq 1 6); do
    #ansible -i ./inventory clients -a "mount -t nfs 10.100.7.${i}:/nfs${j} /mount/nfs${j}"
    #ansible -i ./inventory clients -a "mount -t nfs -o proto=tcp,vers=3,nconnect=8 mountvip.arrakis.org:/share${j} /mount/share${j}"
    #ansible -i ./inventory clients -a "mount -t nfs -o proto=tcp,vers=3,nconnect=12,remoteports=33.20.1.10-33.20.1.21 protocolvip.arrakis.org:/share${j} /mount/share${j}"
    ansible -i ./inventory clients -a "mount -t nfs -o proto=tcp,vers=3,nconnect=12 vastdata1.arrakis.org:/share${j} /mount/share${j}"
    ((j++))
done


# mount -t nfs -o proto=tcp,vers=3,nconnect=8,remoteports=10.132.0.211~10.132.0.214~10.132.0.221~10.132.0.229~10.132.0.230~10.132.0.233 mountvip.arrakis.org:/share${j} /mount/share${j}