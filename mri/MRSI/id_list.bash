#!/usr/bin/env bash

rawloc=/Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/
for d in $rawloc/1*_2*/; do
   link=$(find  $d/ -type l -print -quit) 
   [ -z "$link" ] && continue
   mrid=$( readlink $link | sed 's:.*Mech/\([^/]*\)/.*:\1:')
   [ -z "$mrid" ] && continue
   echo $(basename $d) $mrid
done | tee $(dirname $0)/txt/ids.txt
