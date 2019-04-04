#!/usr/bin/env bash

if [ $(whoami) != "lncd" ]; then
   sudo -u lncd $0 $@
   exit
fi

# 
# 20180912 - long overdue script to sync from usb 
#
[ ! -d /mnt/usb/Data/Luna ] && echo -e "no /mnt/usb/Data/Luna, consider:\n sudo mount /dev/sde2 /mnt/usb" && exit 1

# folders on 7t look like yyyymmddLuna with some number of digits after
# usually just yyyymmddLuna[12], but sometimes yyyymmddLuna-xxxxx (xxxx = lunaid)
rsync --size-only -avhi /mnt/usb/Data/Luna*/20*Luna{,*[0-9]} /Volumes/Hera/Raw/MRprojects/7TBrainMech/ $@
