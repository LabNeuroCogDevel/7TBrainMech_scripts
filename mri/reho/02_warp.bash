#!/usr/bin/env bash
set -euo pipefail

ref=/opt/ni_tools/standard_templates/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c_brain_2mm.nii
for native_reho in images/1*_2*/reho*[^i].nii.gz; do
  warped=${native_reho/.nii.gz/_space-mni.nii.gz}
  [ -r "$warped" ] && continue

  luna_visit=$(ld8 "$native_reho") 

 dryrun applywarp --in="$native_reho" \
            --out="$warped" \
            --warp=/Volumes/Zeus/preproc/7TBrainMech_rest/MHT1_2mm/"$luna_visit"/mprage_warpcoef.nii.gz \
            --ref=$ref \
            --rel --interp=nn
done
