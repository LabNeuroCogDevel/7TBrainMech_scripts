#!/usr/bin/env bash
set -euo pipefail
set -x
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# combine all_csi into bucketed files
#  20190607WF  - depends on spreadsheet.csv header which is less consitatnt for _SD
#              - CRLB is reproted inverted (1/SD) -- originally for afni thresholding
#               which files are in each nii are saved to textfile: nii/all_GABA_SD_inv..txt

txt_and_bucket(){
   [ -r nii/all_$1.nii.gz ] && cat >/dev/null && return 0
   sed "s/$/['$1$2']/" |
   xargs 3dinfo -n4 -iname |
   awk '($1==24){print $5}'| 
   tee nii/all_$1.txt |
   xargs 3dbucket -prefix nii/all_$1.nii.gz
}

for t in GABA_Cre.nii Glu_Cre.nii GABA_SD_inv. Glu_SD_inv.n; do
    find /Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI/all_csi.nii.gz |
    txt_and_bucket $t '[0]'
done

for t in FractionGM MaxTissueProb; do
    find /Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI/all_probs.nii.gz |
    txt_and_bucket $t ''
done

#  3dinfo -label /Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI/all_csi.nii.gz |tr '|' '\n'|egrep -i 'Glu|Gab'|sort|uniq -c|sort -n
#  1 GABA_Cr.nii[0]
#  1 Glu_Cr.nii[0]
#  1 Glu_Gln_Cr.n[0]
#  7 inv_GABA_SD.[0]
#  7 inv_Glu_Gln_[0]
#  7 inv_Glu_SD.n[0]
#  78 GABA_SD_inv.[0]
#  78 Glu_Gln_SD_i[0]
#  78 Glu_SD_inv.n[0]
#  84 GABA_Cre.nii[0]
#  84 Glu_Cre.nii[0]
#  84 Glu_Gln_Cre.[0]
#  85 GABA.nii[0]
#  85 Glu_Gln.nii[0]
#  85 Glu.nii[0]

