#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)

#
# make new labels by removing some from older labels
#  20200207WF  init - remove Left Thal, L&R MOG & SFS

oldlabel="labels_18MP20200117.txt"
oldnii=ROI_mni_18MP_20200117.nii.gz
newname=13MP20200207
3dCM -all_rois $oldnii | sed 1d | paste - - |sed 1d| awk '{print $3,$4,$5}'|
 paste $oldlabel - |
 grep -Pv 'MOG|L.*Thal|SFS' >  labels_${newname}.txt

paste <(sed 's/.*:\t//' labels_$newname.txt) <(seq 1 $(wc -l < labels_${newname}.txt) ) |
   3dUndump -overwrite -prefix ROI_mni_${newname}.nii.gz -master $oldnii -srad 9 -orient RAI -xyz -
