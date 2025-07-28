#!/bin/bash
# Ansible ad hoc commands to setup NFS mounts on clients
# Brute force - no error checking.


function mkdirs () {
  for i in $(seq 1 8); do
    echo "ansible -i ./inventory clients -a \"mkdir -p /mount/share${i}\""
    ansible -i ./inventory clients -a "mkdir -p /mount/share${i}"
  done
}

function mountall_shares () {
  for i in $(seq 1 8); do
    client="linux0${i}"
    share="/mount/share${i}"
    echo "ansible -i ./inventory $client -a \"mkdir -p $share\""
    ansible -i ./inventory $client -a "mkdir -p $share"
  done
}

function mount_shares () {
  j=1
  for i in $(seq 1 8); do
    client="linux0${i}"
    share="/mount/share${i}"

    echo "ansible -i ./inventory $client -a "mount -t nfs -o proto=tcp,vers=3,nconnect=8,remoteports=33.20.1.11-33.20.1.14 sharevip.arrakis.org:/share${i} /mount/share${i}""
    ansible -i ./inventory $client -a "mount -t nfs -o proto=tcp,vers=3,nconnect=8,remoteports=33.20.1.11-33.20.1.14 sharevip.arrakis.org:/share${i} /mount/share${i}"
    ((j+=2))
  done    
}

function run_elbencho_mixed () {
  for i in $(seq 1 8); do
    client="linux0${i}"
    echo "Starting elbencho on $client..."
    ansible -i ./inventory "$client" -m shell \
      # Maximize sequential throughput
      -a "nohup elbencho -t 2 --iodepth 4 --timelimit 2400 -b 1M --direct -s 100G -N 1000 -n 10 -D -F -d -w --rand /mount/share${i} > /tmp/elbencho.log 2>&1 &" &
  done

  wait
  echo "elbencho test started on all clients."
}

function run_elbencho_seq () {
  for i in $(seq 1 8); do
    client="linux0${i}"
    echo "Launching sequential write test on $client..."
    ansible -i ./inventory "$client" -m shell -a \
      "nohup elbencho -t 2 --iodepth 4 --timelimit 2400 -b 4M --direct -s 100G -N 4 -n 2 -w /mount/share${i} > /tmp/elbencho_write.log 2>&1 &" &
  done

  wait
  echo "Sequential write test running on all clients."
}


function parse_elbencho_results () {
  echo "==== Elbencho Throughput Summary (MB/s) ===="
  total=0

  for i in $(seq 1 8); do
    client="linux0${i}"
    echo -n "$client: "
    
    # Extract throughput (assumes "MB/s" appears in elbencho output)
    rate=$(ansible -i ./inventory "$client" -m shell -a "grep -i 'MB/s' /tmp/elbencho_write.log | tail -1" \
           | grep -oE '[0-9]+\.[0-9]+ MB/s' | grep -oE '[0-9]+\.[0-9]+')

    if [[ -n "$rate" ]]; then
      printf "%8.2f MB/s\n" "$rate"
      total=$(echo "$total + $rate" | bc)
    else
      echo "No data"
    fi
  done

  echo "--------------------------------------------"
  printf "TOTAL: %8.2f MB/s\n" "$total"
}


#mkdirs
#mountall_shares
#mount_shares
#run_elbencho_mixed
run_elbencho_seq

# elbencho -t 2 --iodepth 4 --timelimit 2400 -b 4M --direct -s 100G -N 4 -n 2 -w /mount/share${i}
# -t 2: 2 threads (can go higher to match available CPUs/disks)
# --iodepth 4: Queue depth for async I/O
# --timelimit 2400: Run up to 40 minutes
# -b 4M: Large block size to maximize throughput
# --direct: Use O_DIRECT to bypass cache
# -s 100G: Each file = 100GB
# -N 4: 4 files per thread
# -n 2: 2 passes over each file
# -w: Sequential write test (omit --rand for sequential I/O)

# "nohup elbencho -t 2 --iodepth 4 --timelimit 2400 -b 1M --direct -s 100G -N 1000 -n 10 -D -F -d -w --rand /mount/share${i} > /tmp/elbencho.log 2>&1 &" &



### Misc mount commands
#ansible -i ./inventory clients -a "mount -t nfs 10.100.7.${i}:/nfs${j} /mount/nfs${j}"
#ansible -i ./inventory clients -a "mount -t nfs -o proto=tcp,vers=3,nconnect=8 mountvip.arrakis.org:/share${j} /mount/share${j}"
#ansible -i ./inventory clients -a "mount -t nfs -o proto=tcp,vers=3,nconnect=12,remoteports=33.20.1.10-33.20.1.21 protocolvip.arrakis.org:/share${j} /mount/share${j}"
#ansible -i ./inventory clients -a "mount -t nfs -o proto=tcp,vers=3,nconnect=12 vastdata1.arrakis.org:/share${j} /mount/share${j}"
#ansible -i ./inventory $client -a "mount -t nfs -o proto=tcp,vers=3,nconnect=8 sharevip${j}.arrakis.org:/share${i} /mount/share${i}"
#mount -t nfs -o proto=tcp,vers=3,nconnect=8,remoteports=10.132.0.211~10.132.0.214~10.132.0.221~10.132.0.229~10.132.0.230~10.132.0.233 mountvip.arrakis.org:/share${j} /mount/share${j}o
#mount -t nfs -o vers=3,nconnect=16,remoteports=$vip1-$vip8,spread_reads,spread_writes $vip1:/myexport /mnt/vast