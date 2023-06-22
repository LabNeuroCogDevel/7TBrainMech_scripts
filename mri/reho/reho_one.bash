#!/usr/bin/env bash
set -euo pipefail
#
# run ReHo using individual rest file
#
# 20230622WF - skeleton
#

## check inputs
if [ $# -ne 1 ]; then
   echo "USAGE: $0 /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp_nosmooth/10129_20180917/Wbgrndkm_func.nii.gz

   where only input argument is a 4D nifti timeseries to use with reho" 
  exit 1
fi
rest_input=${1}; shift
[ ! -r "$rest_input" ] && warn "cannot read '$rest_input'; should be 4d nifti image" && exit 2

## determine what the output should bee
ld8=$(ld8 "$rest_input")
reho_output=out/${ld8}_reho.nii.gz
# don't need to do anything if we already have file. 0 status is successs
test -r "$reho_output" && echo "# already have '$reho_output'; rm to redo" && exit 0

## need to find gm mask
gmmask=$(find /Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/*/"$ld8"/mri/gmmask.nii.gz -print -quit)
[ -z "$gmmask" ] && warn "ERROR: $ld8 has no gmmask.nii.gz!?" && exit 3


# TODO: run reho on rest_input, save to output
echo "# use $rest_input to make $reho_output. need to resample mask '$gmmask'"
echo see: 3dReHo -help
echo look at 01_reho.bash as wrapper

