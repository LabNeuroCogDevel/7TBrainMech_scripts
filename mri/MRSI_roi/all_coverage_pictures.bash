#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error; [ -v xpid ] && kill $xpid"' EXIT SIGINT

#  20210602WF  
# use afni and plugouts_driver to snap pictures of MRSI roi coverage
# use imagemagic (montage) to put into one image
#
# using coordinates from  roi_locations/labels_13MP20200207.txt 
# somewhat arbitrarily picked ACC, DLPFC, and Insula as ROIs to center on
#
# all_13MP20200207_cnt_masked.nii.gz from all_coverage.bash


jpeg_com() {
   for img in sagittal coronal axial; do
      echo "-com 'SAVE_JPEG ${img}image ${1}_$img.jpg blowup=2'"
   done
}
jump_save() {
   save=$1;shift;
   echo "-com 'SET_SPM_XYZ $@'" $(jpeg_com $save)
}

export DISPLAY=:100
Xvfb $DISPLAY &
xpid=$!
echo "waiting 5 for Xvfb at $xpid"
sleep 5

afni \
  -com "SET_OVERLAY all_13MP20200207_cnt_masked.nii.gz" \
  -com 'SEE_OVERLAY +' \
  -com 'SET_XHAIRS OFF' \
  -YESplugouts \
 /opt/ni_tools/standard/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c.nii \
 /Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/all_13MP20200207_cnt_masked.nii.gz
 
# wait for afni to finish loading
echo "waiting 5 seconds for afni"
sleep 5

test -d img/roi_coverage || mkdir -p $_

# snap shots for each window of each roi
eval plugout_drive \
   $(jump_save img/roi_coverage/AnteriorInsula 38 -6 14 )\
   $(jump_save img/roi_coverage/ACC 2 34 22) \
   $(jump_save img/roi_coverage/DLPFC 46 -38 24) \
   -quit

montage -background black -mode Concatenate -tile 3x3 \
   img/roi_coverage/{ACC,Ant,DLPFC}* \
   img/roi_coverage/concat_ACC_Insual_DLPFC.jpg

kill $xpid
