#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# use database to find raw dirs that have not been processed
#  20190729WF  init

psql -h arnold.wpic.upmc.edu lncddb lncd -AF$'\t' -qtc "
 select id || '_' || to_char(vtimestamp,'YYYYmmdd') as sesid
    from visit natural join visit_study natural join enroll
    where study like 'Brain%' and
          etype like 'LunaID' and
          vtype like 'Scan'
   order by vtimestamp desc"|
 while read ld8; do
    [ -d /Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/$ld8 ] && continue
    echo "${ld8##*_}Luna*"
 done |
 xargs -n1 find  /Volumes/Hera/Raw/MRprojects/7TBrainMech/ -maxdepth 1 -type d -iname 
