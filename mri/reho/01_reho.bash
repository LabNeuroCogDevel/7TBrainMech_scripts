#!/usr/bin/env bash
#
# run reho for nosmooth,nowarp 7T preprocessed rest images
#
# 20230622WF - skeleton
#

for rest_input in /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp_nosmooth/1*_2*/Wbgrndkm_func.nii.gz; do
   # what should output file look like
   ./reho_one.bash "$rest_input"

   # TODO: remove break when working
   break
done
