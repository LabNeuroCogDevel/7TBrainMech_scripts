#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# get status of MRSI processing
#

exists(){ echo -n "$1 $2 "; [ -n "$3" -a -r "$3" ] && echo 1 || echo 0; }
existb(){ exists $1 $(basename "$2") "$2"; }

# find everyone with a slice_PFC or preproc directory
ls -d /Volumes/Hera/Projects/7TBrainMech/subjs/*/{preproc,slice_PFC} |
 xargs -n1 dirname | sort -u | while read d; do
   d=$d/slice_PFC
   [[ $d =~ [0-9]{5}_[0-9]{8} ]] || continue
   ld8=${BASH_REMATCH}
   mrid=$( (grep $ld8 txt/ids.txt || echo NA NA) | cut -f2 -d' ' |sed 1q)
   echo $ld8 mrid $mrid
   sheet=$(find /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/ \
      -iname 'spreadsheet.csv' -ipath "*/$mrid*" -print -quit )
   regout=$(find /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/ \
      -iname '*registration_out' -type d -ipath "*/$mrid*" -print -quit )
   existb $ld8 $d/MRSI
   exists $ld8 sheet $sheet
   exists $ld8 regout $regout
   existb $ld8 $d/MRSI/scout_resize.nii
   existb $ld8 $d/MRSI/all_csi.nii.gz
   existb $ld8 $d/MRSI/all_probs.nii.gz
done |  tee >(cat >&2) | Rscript -e 'write.table(row.names=F, quote=F, file="txt/status.txt", tidyr::spread(read.table(file("stdin")),V2,V3))'
