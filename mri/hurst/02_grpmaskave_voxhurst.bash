#!/usr/bin/env bash
# extract mean roi values from voxelwise hurst
#
# *** see Makefile *** for various incantations
#
#   hurst_nii.py  and  hurst_wholebrain.m
#         for voxwise images
#   ../MRSI_roi/coverage_roi4d.py + 3dUndump for input mask (manual placed) + gm_mask.bash
#   ../MRSI_roi/roi_locations/labels_13MP20200207.txt for labels
#       for roi atlases
#
# maskave_grp and warn from lncdtools
# 
# NB. gm_mask.bash need to remove what would be zeros from roi averages?
#
# original MNI atlas center seeds (before placment and coverage re-adjustment)
#     7	ACC:	2 -34 22
#     8	MPFC:	0 -54 28
#     9	R DLPFC:	-46 -38 24
#    10	L DLPFC:	42 -42 28
outcsv=${1:?need first argument as output csv file, e.g. stats/voxelwise_py_dlpfc-acc-mpfc.csv};
inmask=${2:?need second argument to be input ROI mask. probably atlas/13MP20200207_mancov-centered_GMgt0.5-mask.nii.gz};
! test -r "$inmask" && warn "cannot find input mask $_" && exit 1
! [[ $outcsv =~ .csv$ ]] && echo "first argument '$outcsv' must be output csv file, should end with .csv" && exit 1
shift 2; # remove first 2 required args.
# rest of inputs are files to run on. use dencrct_matlb_h as default b/c that's what we started with in Makefile
# modified to find python files (mp)
[ $# -eq 0 ] &&
   all_files=(hurst_nii/1*_2*/py_dencrct_hurst_rs.nii.gz) ||
   all_files=("$@")
3dmaskave_grp \
   -roistats 1 \
   -csv "$outcsv" \
   -m "ACC=$inmask<7>" \
   -m "MPFC=$inmask<8>" \
   -m "RDLPFC=$inmask<9>" \
   -m "LDLPFC=$inmask<10>" \
   --  "${all_files[@]}"
