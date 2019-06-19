#!/usr/bin/env bash



# 20190425 - maria orma  (MPOR) rois
# recenter
echo ../mkcoords/01_11323_spheres_to_mni_cm.bash
# 20190411 - make what is now csi_rois_mni_FC_20190411.nii.gz 
# perl -F: -slane '$F[1] =~ s/,//g;print $F[1], " $."' mni_coords.txt > mni_coords_nolabel.txt
# 3dUndump \
#    -prefix csi_rois_mni.nii.gz \
#    -master /opt/ni_tools/standard/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c_2mm.nii \
#    -srad 9 \
#    -xyz  mni_coords_nolabel.txt
