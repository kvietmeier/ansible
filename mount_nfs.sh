#!/bin/bash
# Ansible ad hoc commands to setup NFS mounts on clients
# Brute force - no error checking.

#for i in $(seq 1 8); do
#    echo "ansible -i ./inventory clients -a \"mkdir -p /mount/share${i}\""
#    ansible -i ./inventory clients -a "mkdir -p /mount/share${i}"
#done

#for i in $(seq 1 8); do
#    client="linux0${i}"
#    share="/mount/share${i}"
#    echo "ansible -i ./inventory $client -a \"mkdir -p $share\""
#    ansible -i ./inventory $client -a "mkdir -p $share"
#done

#j=1
#for i in $(seq 1 8); do
#    client="linux0${i}"
#    share="/mount/share${i}"

    #ansible -i ./inventory clients -a "mount -t nfs 10.100.7.${i}:/nfs${j} /mount/nfs${j}"
    #ansible -i ./inventory clients -a "mount -t nfs -o proto=tcp,vers=3,nconnect=8 mountvip.arrakis.org:/share${j} /mount/share${j}"
    #ansible -i ./inventory clients -a "mount -t nfs -o proto=tcp,vers=3,nconnect=12,remoteports=33.20.1.10-33.20.1.21 protocolvip.arrakis.org:/share${j} /mount/share${j}"
    #ansible -i ./inventory clients -a "mount -t nfs -o proto=tcp,vers=3,nconnect=12 vastdata1.arrakis.org:/share${j} /mount/share${j}"
    #ansible -i ./inventory $client -a "mount -t nfs -o proto=tcp,vers=3,nconnect=8 sharevip${j}.arrakis.org:/share${i} /mount/share${i}"
#    echo "ansible -i ./inventory $client -a "mount -t nfs -o proto=tcp,vers=3,nconnect=8,remoteports=33.20.1.11-33.20.1.14 sharevip.arrakis.org:/share${i} /mount/share${i}""
#    ansible -i ./inventory $client -a "mount -t nfs -o proto=tcp,vers=3,nconnect=8,remoteports=33.20.1.11-33.20.1.14 sharevip.arrakis.org:/share${i} /mount/share${i}"
#    ((j+=2))
#done


for i in $(seq 1 8); do
   client="linux0${i}"
   ansible -i ./inventory $client -m shell -a "elbencho -t 2 --iodepth 4 --timelimit 2400 -b 1M --direct -s 100G -N 1000 -n 10 -D -F -d -w --rand /mount/share${i}" &
done

wait


# mount -t nfs -o proto=tcp,vers=3,nconnect=8,remoteports=10.132.0.211~10.132.0.214~10.132.0.221~10.132.0.229~10.132.0.230~10.132.0.233 mountvip.arrakis.org:/share${j} /mount/share${j}o

#mount -t nfs -o vers=3,nconnect=16,remoteports=$vip1-$vip8,spread_reads,spread_writes $vip1:/myexport /mnt/vast