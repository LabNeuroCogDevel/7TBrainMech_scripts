#!/usr/bin/env bash

# allow debugging with
#   DRYRUN=1 ./01_gm_mask.bash
[ -v DRYRUN ] && DYRUN=echo || DRYRUN=

GMMASK="" # TODO: find/set 
# if using probability mask instead of binary might need step(g-$gmthres)
# NB. the mask should be the same voxel size and FOV as the coverage_ratio files
#  if not you can get around the error by forcing it
#    3dresample -rmode NN -master coverage_ratio.nii.gz -inset gmmask -prefix gmmask_rs.nii.gz
for roi in rois/*/coverage_ratio.nii.gz; do
   out=${roi/.nii.gz/_gm.nii.gz}
   $DRYRUN 3dcalc -overwrite -expr "step(g)*r" -prefix "$out" -r "$roi" -g "$GMMASK"
done
