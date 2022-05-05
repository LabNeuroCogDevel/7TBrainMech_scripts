#!/usr/bin/env bash

# currently have a file per roi with voxel values of "coverage ratio"
# but we'll replace all voxels above whatever coverage threshold with roi's numeric value
# (all other voxels set to zero)

coverthres=.5 # TODO: set me
for roi_gm in rois/*/coverage_ratio_wm.nii.gz; do
   # use regexp to extract roi number from mask path
   # used to put roi number back into the nifti.
   # e.g.    rois/01_R_Anterior_Insula/coverage_ratio.nii.gz
   # matches       1
   ! [[ $roi_gm =~ /0?([0-9]+)_ ]] && echo "no roi num in name of $roi_gm" && continue
   roi_num=${BASH_REMATCH[1]}
   
   out=${roi_gm/.nii.gz/_thres$coverthres.nii.gz}
   echo "# writting $out"
   # TODO: remove echo after confirm working
   echo 3dcalc -overwrite -r "$roi_gm" -expr "step(r-$coverthres)*$roi_num" -prefix "$out"
done
