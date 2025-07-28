#!/bin/bash
# Ansible ad hoc commands to run elbencho
# Brute force - no error checking.

for i in $(seq 1 8); do
   client="linux0${i}"
   ansible -i ./inventory $client -m shell -a "elbencho -t 2 --iodepth 8 --timelimit 2400 -b 1M --direct -s 100G -N 1000 -n 10 -D -F -d -w --nolive /mount/share${i}" &
done

wait