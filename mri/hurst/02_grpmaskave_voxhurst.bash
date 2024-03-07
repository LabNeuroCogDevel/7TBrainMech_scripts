#!/usr/bin/env bash
# extract mean roi values from voxelwise hurst
# see Makefile
#   hurst_wholebrain.m for voxwise files
#   ../MRSI_roi/coverage_roi4d.py + 3dUndump for input mask
#   ../MRSI_roi/roi_locations/labels_13MP20200207.txt for labels
#   
# maskave_grp and warn from lncdtools
#
# original MNI atlas center seeds (before placment and coverage re-adjustment)
#     7	ACC:	2 -34 22
#     8	MPFC:	0 -54 28
#     9	R DLPFC:	-46 -38 24
#    10	L DLPFC:	42 -42 28
inmask=${1:?need first argument to be input ROI mask. probably ../MRSI_roi/13MP20200207_covcentered.nii.gz};
! test -r "$inmask" && warn "cannot find input mask $_" && exit 1
outcsv=${2:?need second argument as output csv file, probably want stats/voxelwise_meanH_dlpfc-acc-mpfc.csv};
shift 2; # remove first 2 required args.
# rest of inputs are files to run on. use dencrct_matlb_h as default b/c that's what we started with in Makefile
[ $# -eq 0 ] &&
   all_files=(hurst_nii/1*_2*/dencrct_matlab_H.nii.nii) ||
   all_files=("$@")
3dmaskave_grp \
   -csv "$outcsv" \
   -m "ACC=$inmask<7>" \
   -m "MPFC=$inmask<8>" \
   -m "RDLPFC=$inmask<9>" \
   -m "LDLPFC=$inmask<10>" \
   --  "${all_files[@]}"
