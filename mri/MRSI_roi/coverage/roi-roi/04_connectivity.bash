#!/usr/bin/env bash

# allow debugging with
#   DRYRUN=1 ./04_connectivity.bash
[ -v DRYRUN ] && DYRUN=echo || DRYRUN=

#TODO: remove this
DRYRUN=echo

# TODO: confirm matches earlier
coveragethres=.5

# TODO: confrim all_rois_$coveragethes.nii.gz is same voxel dim and FOV
# like GM mask note in 01_gm_mask.bash
# if not, can use
# 3dresample -inset all_rois_$coverage.nii.gz -master $example_ts -prefix all_rois_${coverage}_rs.nii.gz 

ROIFILE=all_rois_$coveragethres.nii.gz
[ ! -r $ROIFILE ] && echo "cannot read $ROIFILE! maybe rerun 03_combine.bash?" && exit 1

for ts in /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost/*/brnswdkm_func_4.nii.gz; do
  ld8=$(ld8 $ts)
  prefix=mat/mni/$ld8/corrmat${coveragethres}_
  $DRYRUN mkdir -p $(dirname $prefix)
  $DRYRUN @ROI_Corr_Mat -ts $ts -roi $ROIFILE -prefix $prefix
  # TODO: remove to run all
  break 
done

