#!/usr/bin/env bash

# setup passwordless rsync
passfile=$(cd $(dirname $0);pwd)/mesonpass.txt
[ ! -r $passfile ] && echo "need meson password in $passfile" && exit 1


# folders on 7t look like yyyymmddLuna with some number of digits after
# usually just yyyymmddLuna[12], but sometimes yyyymmddLuna-xxxxx (xxxx = lunaid)
sshpass -f "$passfile" rsync --size-only -azvhi 7t:/twix/7t/20*Luna{,*[0-9]} /Volumes/Hera/Raw/MRprojects/7TBrainMech/ $@
