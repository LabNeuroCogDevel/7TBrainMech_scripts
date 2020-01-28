#!/usr/bin/env bash
set -eou pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# use coord_builder exported subject roi in mni space to build centered rois
#  1. get center of mass for the weirdly shaped subject rois in mni space
#  2. make new uniform rois with that center
#

# log
# 20200128 - push files into out/$ld8/*

## do we have what we need? should we show help?
[ $# -ne 2 ] && echo "USAGE:
  $0 mni_roi_name.nii.gz subj_roi_warped_to_mni.nii.gz 

  where:
   'mni_roi_name.nii.gz' will be created (by fiding center of mass and redrawing rois there)
   'subj_roi_warped_to_mni.nii.gz' comes from coord_mover.m; see 'coord_builder.bash view'

  EXAMPLE:
   $0 mni_coords_MPOR_20190425.nii.gz ../mni_examples/empty_coords_737702.522808_MP_for_mni.txt_mni.nii.gz
   
" && exit 1
name="$1"
roi_mni="$2"

# roi_mni="../mni_examples/empty_coords_737702.522808_MP_for_mni.txt_mni.nii.gz"
# name="ROI_MNI_MP_20191004.nii.gz"
[ ! -r $roi_mni ] && echo "cannot read subject mni warped roi file: '$roi_mni'" && exit 1
roi_mni="$(readlink -f $roi_mni)" # make absolute path

# do everying in coordmover directory
cd $(dirname $0)

### files we will create ##
bn=$(basename "$name" .nii.gz)
cm_mni_out=/tmp/mni_coords_${bn}_RAI.txt
cm_nolab=/tmp/mni_coords_${bn}_nolabels.txt
ld8=$(ld8 $bn)
outdir=out/$ld8 
test ! -d "$outdir" && mkdir -p $_
# outputs we care about
final_mniSpheres=$outdir/$name
final_coordstxt=$outdir/${bn}_labeled.txt

[ -r "$final_mniSpheres" ] && echo "have '$final_mniSpheres'; rm to reurn" && exit 0

# get center of mass of unusually shaped rois now in mni space
3dCM -all_rois $roi_mni | 
   egrep '^[-0-9]|#ROI'|
   paste - - |
   tee $cm_mni_out

# redo roi generation wit the new roi locations
# but b/c we are in LPI and afni wants RAI: -1*x and -1*y
perl -slane 'print join(" ",-1*$F[2], -1*$F[3],$F[4],$F[1]) if $.>1' $cm_mni_out > $cm_nolab
3dUndump \
   -prefix $final_mniSpheres \
   -master /opt/ni_tools/standard/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c_2mm.nii \
   -srad 9 \
   -xyz $cm_nolab \
   -overwrite
3dNotes -h "$0 $*" $final_mniSpheres 

# generate new coordinate list
# TODO: need correct labels for this -- repalce `echo | sed` with `sed '' labels.txt`
paste -d: <(echo | sed 's/  .*[0-9].*/ /' )  $cm_nolab|sed 's/ :/: /' >  $final_coordstxt
echo "made $(pwd)/$final_mniSpheres and $(pwd)/$final_coordstxt"

