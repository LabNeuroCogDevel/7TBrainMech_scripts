#!/usr/bin/env bash

# allow debugging with
#   DRYRUN=1 ./04_connectivity.bash
[ -v DRYRUN ] && DYRUN=echo || DRYRUN=

#TODO: remove this
DRYRUN=echo

# TODO: confirm matches earlier
coveragethres=.5

ROIFILE=all_rois_$coveragethres.nii.gz
[ ! -r $ROIFILE ] && echo "cannot read $ROIFILE! maybe rerun 03_combine.bash?" && exit 1

for ts in /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost/*/brnswdkm_func_4.nii.gz; do
  ld8=$(ld8 $ts)
  prefix=mat/$ld8/corrmat${coveragethres}_
  $DRYRUN mkdir -p $(dirname $prefix)
  $DRYRUN @ROI_Corr_Mat -ts $ts -roi $ROIFILE -prefix $prefix
  # TODO: remove to run all
  break 
done

