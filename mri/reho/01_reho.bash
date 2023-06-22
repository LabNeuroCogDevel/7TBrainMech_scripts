#!/usr/bin/env bash
#
# run reho for nosmooth,nowarp 7T preprocessed rest images
#
# 20230622WF - skeleton
#

echo files like /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp_nosmooth/10129_20180917/Wbgrndkm_func.nii.gz
echo see: 3dReHo -help

for rest_input in /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp_nosmooth/1*_2*/Wbgrndkm_func.nii.gz; do
   # what should output file look like
   ld8=$(ld8 "$rest_input")
   reho_output=out/${ld8}_reho.nii.gz

   # dont need to do anything if we already have file
   test -r "$reho_output" && echo "# already have '$reho_output'; rm to redo" && continue

   # TODO: run reho on rest_input, save to output
   echo "# use $rest_input to make $reho_output"


   # TODO: remove break when working
   break
done
