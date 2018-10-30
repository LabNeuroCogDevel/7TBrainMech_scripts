#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

# find raw dicom list dirs
#   like '*DCM*' (usually ALLDCM) 
#   should have more than 300 files (slow to determine!)
# save to inputdirs.txt

cd $(dirname $0)
source func.bash # getld8_dcmdir
for d in /Volumes/Hera/Raw/MRprojects/7TBrainMech/*/*DCM*/; do 
   # skip if too few (might have a dicom mprage only directory)
   needatleast=300
   n=$(find $d -maxdepth 1 -mindepth 1 -iname '*IMA' |sed ${needatleast}q|wc -l)
   [ $n -ne ${needatleast} ] && echo "# skipping $d, too few dicoms ($n<$needatleast)" >&2

   #dicom_hinfo -no_name -tag 0010,0010 $(find $d -maxdepth 1 -mindepth 1 -iname '*IMA' -print -quit) | 
   #perl -slne 'print "$SDir\t${1}_${2}\tsub-$1/$2" if m/(\d{5})_(\d{8})/' -- -SDir=$d;
   ld8=$(getld8_dcmdir $d) || continue
   [ -z "$ld8" ] && continue
   echo -e "$d\t$ld8\tsub-${ld8/_/\/}"

done | tee inputdirs.txt
