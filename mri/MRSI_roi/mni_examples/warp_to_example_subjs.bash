#!/usr/bin/env bash
set -euo pipefail
cd $(dirname "$0")
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# warp some mni coordinates to example subjects
# code taken from 000_setupdirs.bash
#  20191009WF  init

[ $# -le 1 ] && echo "USAGE:
  $0 mni_rois.nii.gz ld8_1 ld8_2
  ./warp_to_example_subjs.bash ../mkcoords/ROI_mni_MP_20191004.nii.gz 10129_20180917 11734_20190128 
" && exit 1


mni_atlas="$1"; shift
[ ! -r $mni_atlas ] && echo "need an mni atlas to warp around" && exit 1

warp_to_scout(){
   local ld8="$1"
   [ -z "$ld8" ] && echo "$FUNCNAME: no ld8" && return 1

   local t1_to_pfc="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/mprage_to_slice.mat"
   local pfc_ref="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/slice_pfc.nii.gz"
   local mni_to_t1="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/ppt1/template_to_subject_warpcoef.nii.gz"
   local scout_t1="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/mprage_in_slice.nii.gz"
   local parc_res="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI/parc_group/rorig.nii"

   for v in t1_to_pfc pfc_ref mni_to_t1 scout_t1 parc_res; do
      [ ! -r "${!v}" ] && echo "cannot find $v: '${!v}'; try: ../../MRSI/01_get_slices.bash $ld8" && return 1
   done

   local outimg="scout_space/$(basename "$mni_atlas" .nii.gz)/${ld8}_scout.nii.gz"
   local outimg_res="scout_space/$(basename "$mni_atlas" .nii.gz)/${ld8}_scoutres.nii.gz"
   [ ! -d "$(dirname $outimg)" ] && mkdir -p "$(dirname $outimg)"

   local cm_out="${outimg/.nii.gz/}_cm.txt"
   [ -r "$cm_out" ] && echo "# have $ld8; rm $cm_out # to redo" && return 0

   echo "$(pwd)/$outimg"
   local cmd="applywarp -o $outimg -i $mni_atlas -r $pfc_ref -w $mni_to_t1 --postmat=$t1_to_pfc --interp=nn"
   eval "$cmd"
   3dNotes -h "$cmd # $0 $@" $outimg

   lnscout="$(dirname $outimg)/${ld8}_$(basename $scout_t1)"
   [ ! -e "$lnscout" ] && ln -s  $scout_t1 $lnscout

   # write out center of mass for each roi
   3dresample -inset $outimg \
     -master $parc_res \
     -prefix $outimg_res -rmode NN
   3dCM -local_ijk -all_roi "$outimg_res" | egrep '^[0-9]|#ROI'|paste - - |cut -f2-4 -d" " > $cm_out

}

for ld8 in $@; do
   warp_to_scout $ld8
done
