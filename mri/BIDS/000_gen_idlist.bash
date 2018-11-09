#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

# find raw dicom list dirs
#   like '*DCM*' (usually ALLDCM) 
#   should have more than 300 files (slow to determine!)
# save to inputdirs.txt:
#  $DCMALL/	$ld8	sub-$l/$d8
# also makes raw_dirs.txt:
#  $ndcm $DCMALL/

cd $(dirname $0)
source func.bash # getld8_dcmdir getld8_db

# create raw dirs if it's been a day
let tdiff=$(date +%s)-$(stat -c%Z raw_dirs.txt||echo 0) 
let aday=60*60*24
[  $tdiff -gt $aday ] && 
  for d in /Volumes/Hera/Raw/MRprojects/7TBrainMech/2*/*/; do 
     n=$(find "$d" -maxdepth 1 -type f -iname '*IMA'|wc -l);
     [ $n -gt 10000 ] && echo $n $d
  done |tee raw_dirs.txt

for rawdir in /Volumes/Hera/Raw/MRprojects/7TBrainMech/2*/; do
   # find dir with most dicoms
   read n d <<< $(sort -nr raw_dirs.txt | grep "$rawdir"  |sed 1q)
   [ -z "$d" -o ! -r "$d" ] && echo "WARNING: no dcm dir for $rawdir" >&2 && continue
   #dicom_hinfo -no_name -tag 0010,0010 $(find $d -maxdepth 1 -mindepth 1 -iname '*IMA' -print -quit) | 
   #perl -slne 'print "$SDir\t${1}_${2}\tsub-$1/$2" if m/(\d{5})_(\d{8})/' -- -SDir=$d;
   ld8=$(getld8 "$d") || : #continue
   [ -z "$ld8" ] && continue
   echo -e "$d\t$ld8\tsub-${ld8/_/\/}"
done > inputdirs.txt
