#!/bin/bash
# Remove hosts from known_hosts

for i in $(cat /etc/hosts | egrep 'centos|ubuntu' | awk '{print $1}'); do ssh-keygen -R $i; done
for i in $(cat /etc/hosts | egrep 'centos|ubuntu' | awk '{print $2}'); do ssh-keygen -R $i; done
