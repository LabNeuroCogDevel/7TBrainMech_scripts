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
# 20200213 - update file paths. leave everything upto inputs. put outputs in the same directory

## do we have what we need? should we show help?
[ $# -ne 2 ] && echo "USAGE:
  $0 subj_roi_warped_to_mni.nii.gz mni_roi_name.nii.gz 

  where:
   'path/to/subj_roi_warped_to_mni.nii.gz' comes from coord_mover.m; see 'coord_builder.bash view'
   'path/to/mni_roi_name.nii.gz' will be created (by fiding center of mass and redrawing rois there)

  EXAMPLE:
   $0 ../mni_examples/empty_coords_737702.522808_MP_for_mni.txt_mni.nii.gz mni_coords_MPOR_20190425.nii.gz 
   
" && exit 1

roi_mni="$1"; shift
final_mniSpheres="$1"; shift

# roi_mni="../mni_examples/empty_coords_737702.522808_MP_for_mni.txt_mni.nii.gz"
# name="ROI_MNI_MP_20191004.nii.gz"
[ ! -r $roi_mni ] && echo "cannot read subject mni warped roi file: '$roi_mni'" >&2 && exit 1
roi_mni="$(readlink -f $roi_mni)" # make absolute path

### files we will create ##
outdir=$(dirname "$final_mniSpheres")
cm_mni_out=$outdir/mni_coords_RAI.txt
cm_nolab=$outdir/mni_coords_nolabels.txt
bn=$(basename "$final_mniSpheres" .nii.gz)
final_coordstxt=$outdir/${bn}_labeled.txt

# always redo
[ -r "$final_mniSpheres" ] && echo "# WARNING: remaking $final_mniSpheres" >&2
#[ -r "$final_mniSpheres" ] && echo "have '$final_mniSpheres'; rm to reurn" >&2 && exit 0

# get center of mass of unusually shaped rois now in mni space
set -x
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
set +x

# add this scripts call to final output
3dNotes -h "$0 $*" $final_mniSpheres 

# generate new coordinate list
# TODO: need correct labels for this -- repalce `echo | sed` with `sed '' labels.txt`
paste -d: <(echo | sed 's/  .*[0-9].*/ /' )  $cm_nolab|sed 's/ :/: /' >  $final_coordstxt
echo "made $final_mniSpheres and $final_coordstxt"

