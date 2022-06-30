#!/usr/bin/env bash

# allow debugging with
#   DRYRUN=1 ./01_gm_mask.bash
[ -v DRYRUN ] && DYRUN=echo || DRYRUN=

GMMASK="" # TODO: find/set 
# if using probly mask instead of binary might need step(g-$gmthres)
for roi in rois/*/coverage_ratio.nii.gz; do
   out=${roi/.nii.gz/_gm.nii.gz}
   $DRYRUN 3dcalc -overwrite -expr "step(g)*r" -prefix "$out" -r "$roi" -g "$GMMASK"
done
