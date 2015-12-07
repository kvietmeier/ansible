#!/bin/bash

# Add hosts to .ssh/known_hosts and copy SSH keys

# By hostname
for i in $(cat /etc/hosts | egrep 'centos|ubuntu' | awk '{print $2}')
  do 
    ssh-keyscan ${i} >> ~/.ssh/known_hosts
    ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@${i}
  done

# By IP Address
for i in $(cat /etc/hosts | egrep 'centos|ubuntu' | awk '{print $1}')
    ssh-keyscan ${i} >> ~/.ssh/known_hosts
    ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@${i}
  done

#for i in $(cat /etc/hosts | egrep 'centos|ubuntu' | awk '{print $2}')
#  do ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@${i}
#done
#
#for i in $(cat /etc/hosts | egrep 'centos|ubuntu' | awk '{print $1}')
#  do ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@${i}
#done
