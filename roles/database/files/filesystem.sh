#!/usr/bin/bash
###=======================================================================================###
#   Modified for Azure by: Karl Vietmeier
#
#   Partition and create filesystem on NVME data disks
#   - called from setup_part_1.sh
#   
###=======================================================================================###

# Don't need this but will put in the default 1st NVME data disk device
# in an Azure VM
DEVICEROOT=nvme0n2
MOUNTPOINT=/voltdbdata

# Usage:
# ./filesystem.sh <device in /dev> <mountpoint>
DEVICEROOT=$1
MOUNTPOINT=$2

# Make sure we pass in the parameters
if [ -z "$1" ] || [ -z "$2" ]
  then
    echo "Usage: filesystem.sh <device> <mountpoint>"
    exit
fi

DEVICE=/dev/${DEVICEROOT}

echo DEVICE=${DEVICE}, MOUNTPOINT=${MOUNTPOINT}

if [ ! -d ${MOUNTPOINT} ]
  then
    echo "Creating ${MOUNTPOINT} mount point..."
    mkdir ${MOUNTPOINT}
fi

if [ "`file -s ${DEVICE}`" = "${DEVICE}: data" ]
  then
    echo "Creating filesystem on ${DEVICE}..."
    mkfs -t ext4  ${DEVICE}
fi

if [ "`df -k | grep ${DEVICEROOT}`" = "" ]
  then
    echo "Mounting ${DEVICE}..."
    mount ${DEVICE} ${MOUNTPOINT}
fi

if [ "`grep ${DEVICE} /etc/fstab`" = "" ]
  then
    echo "Creating fstab entry for ${DEVICE}..."
    cp /etc/fstab /etc/fstab.`date '+%y%m%d_%H%M%ss'`

    UUID=`file -s ${DEVICE} | awk -F= '{ print $2}' | awk {'print $1}'`
    echo "UUID=${UUID}..."
    
    echo "" >> /etc/fstab
    echo "Added for VoltDB for $DEVICEROOT" >> /etc/fstab
    echo "UUID=${UUID} $MOUNTPOINT   ext4    defaults,nofail        0       2" >> /etc/fstab
fi

if [ ! -r ${MOUNTPOINT}/voltdbroot ]
  then
    echo "Creating ${MOUNTPOINT}/voltdbroot... "
    mkdir ${MOUNTPOINT}/voltdbroot
    chown ubuntu ${MOUNTPOINT}/voltdbroot
    chgrp ubuntu ${MOUNTPOINT}/voltdbroot
    chown ubuntu ${MOUNTPOINT}
    chgrp ubuntu ${MOUNTPOINT}
fi
