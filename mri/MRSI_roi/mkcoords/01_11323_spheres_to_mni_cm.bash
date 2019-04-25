#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# use rois defined as ijk within 11323 to get mni coordinates
#
perl -salne 'print join(" ", @F[($#F-2)..$#F], $.)' 11323_example_coords.txt > 11323_example_coords_nolabel.txt
3dUndump \
   -prefix 11323_example_coords.nii.gz \
   -master ../../../../subjs/11323_20180316/slice_PFC/MRSI_roi/raw_finn201904011/rorig.nii \
   -srad 9 \
   -ijk  11323_example_coords_nolabel.txt \
   -overwrite

ld8=11323_20180316
rorig="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI_roi/raw_finn201904011/rorig.nii"
t1_to_pfc="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/mprage_to_slice.mat"
# pfc_ref="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/slice_pfc.nii.gz"
# mni_to_t1="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/ppt1/template_to_subject_warpcoef.nii.gz"
t1_to_mni="/Volumes/Hera/Projects/7TBrainMech/subjs/11323_20180316/slice_PFC/ppt1/mprage_warpcoef.nii.gz"
pfc_to_t1=./${ld8}_slice_to_mprage.mat
template="/Volumes/Hera/Projects/7TBrainMech/subjs/11323_20180316/slice_PFC/ppt1/template_brain.nii"  

convert_xfm -omat $pfc_to_t1 -inverse $t1_to_pfc 
applywarp --premat=$pfc_to_t1  -i 11323_example_coords.nii.gz -o 11323_roi_mni.nii.gz -w  $t1_to_mni -r  $template --interp=nn

3dCM -all_rois 11323_roi_mni.nii.gz | 
   egrep '^[-0-9]|#ROI'|
   paste - - |
   tee mni_coords_MPOR_20190425_RAI.txt

perl -slane 'print join(" ",-1*$F[2], -1*$F[3],$F[4],$F[1]) if $.>1' mni_coords_MPOR_20190425_RAI.txt > mni_coords_MPOR_20190425_nolabels.txt

3dUndump \
   -prefix csi_rois_mni_MPRO_20190425.nii.gz \
   -master /opt/ni_tools/standard/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c_2mm.nii \
   -srad 9 \
   -xyz mni_coords_MPOR_20190425_nolabels.txt \
   -overwrite

paste -d: <(sed 's/  .*[0-9].*/ /' 11323_example_coords.txt)  mni_coords_MPOR_20190425_nolabels.txt|sed 's/ :/: /' >  mni_coords_MPOR_20190425_labeled.txt
