#!/usr/bin/env bash

#
# angle mni into space that looks like MRSI oblique slice
#

mni=/opt/ni_tools/standard/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c.nii
roi=ROI_mni_13MP20200207.nii.gz

3drotate -rotate 17R 0 0 -prefix mni_17R.nii.gz $mni
3drotate -rotate 17R 0 0 -prefix rot/17R.nii.gz $roi
# get new centers from rotation and make into cubes
3dCM -all_rois rot/17R.nii.gz |sed 1d|paste - -|
   perl -slanE 'print join(" ", map {sprintf("%.0f",$_)} (-1*$F[2], -1*$F[3], $F[4], $F[1])) if $F[1] ~~ [1, 2, 7, 8, 9, 10]' |
   3dUndump -srad 3mm -cubes -master rot/17R.nii.gz -prefix roi_cube_subset.nii.gz -overwrite -xyz -

# 11738_20190201 arbitrarly choosen as example
#ex=/Volumes/Hera/Projects/7TBrainMech/subjs/11738_20190201/slice_PFC/mprage_in_slice.nii.gz

# # use oblique transformation matrix in slice sapce
# 3dWarp -oblique_parent mprage_in_slice.nii.gz -prefix mni_obl_3dwarp.nii.gz mni_icbm152_t1_tal_nlin_asym_09c.nii
# 3dWarp -oblique_parent mprage_in_slice.nii.gz -prefix 13MProi_3dwarp.nii.gz ROI_mni_13MP20200207.nii.gz

## prev attempt using warps
# 
# # mprage in scout slice space is missing a lot of top (Superiour) and a bit of bottom (Inferior). zeropad adds that back. The scout slice is also not "high res" (1.6 x 1.6 x 3). we upsample so the warp will sill be 1mm^3
# 3dZeropad -overwrite -S 10 -I 5 -prefix mprage_superior10.nii.gz $ex
# antsRegistrationSyN.sh -t r -d 3 -f mprage_superior10.nii.gz -m $mni -o mni_obliqued
# #3dresample -overwrite -dxyz 1 1 1 -prefix mprage_superior10_1mm.nii.gz -input mprage_superior10.nii.gz
# #antsRegistrationSyN.sh -t r -d 3 -f mprage_superior10_1mm.nii.gz -m $mni -o mni_obliqued
# antsApplyTransforms -i ../roi_locations/ROI_mni_13MP20200207.nii.gz -r mni_obliquedWarped.nii.gz -t mni_obliqued0GenericAffine.mat -o 13MProi.nii.gz
