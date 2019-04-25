#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# get mni coordantes into ijk values (for coord_mover.m)
#

# for displaying
#[ ! -r slice_mni.nii ]; then
    mni=~/standard/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c.nii 
    3dresample \
          -master $mni \
          -inset /opt/ni_tools/slice_warp_gui/slice_atlas.nii.gz \
          -prefix slice_1mm.nii.gz -rmode NN -overwrite
    3dcalc -a slice_1mm.nii.gz -b $mni -expr 'b*(.5+.5*step(a))' -prefix slice_mni.nii -overwrite
    gunzip slice_mni.nii.gz
#fi

cat_matvec slice_mni.nii::IJK_TO_DICOM_REAL > mni_to_ijk.1D
cat mni_coords_nolabel.txt | Vecwarp -matvec mni_to_ijk.1D -backward -output - | cat -n > mni_ijk.txt


