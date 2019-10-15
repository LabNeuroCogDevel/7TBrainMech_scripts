#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)

#
# "build"/place coordinates and inspect them on different subjects
#  20191015WF  init

usage() {
   [ $# -gt 1 ] && msg="$@!\n" || msg=""
 echo -e "${msg}USAGE:
$0 place SUBJ [NUMBER=24]
$0 mkmask MASKNAME mni_examples/SUBJ_MNI_ROI.nii.gz
$0 view SUBJ MASKNAME
$0 mni

example:
$0 place 11734_20190128
$0 mkmask ROI_mni_MP_20191004.nii.gz mni_examples/empty_coords_737713.587918_MP_for_mni.txt_mni.nii.gz
$0 view 10129_20180917 ROI_mni_MP_20191004.nii.gz
$0 mni

see also doc of coord_mover.m
"
   exit 1
}
[ $# -eq 0 ] && usage

mlrun(){ 
   echo "$*"
   matlab -nodesktop -nosplash -r "try; $@; catch e; disp(e); quit(); end"; }



action="$1"; shift
case "$action" in
   place)
      [ $# -lt 1 ] && usage "bad place args"
      subj="$1"; shift
      [ $# -gt 0 ] && n="$1" || n=24
      if [ $n -eq 24 ]; then
         roi_list="tmp/labels_MP20191015.txt"
         coord_list=tmp/MProi20191015.txt
         [ ! -r coord_list ] && seq 1 $n|sed 's/$/\t50\t50/' > $coord_list
      else
         roi_list=tmp/roilist_labels_$n.txt
         coord_list=tmp/empty_coords_$n.txt
         seq 1 $n|sed s/$/:/ > $roi_list
         sed 's/:/\t50\t50/g' $roi_list > $coord_list
      fi
      mlrun "coord_mover('$subj', 'roilist','$roi_list','subjcoords', '$coord_list')"
      ;;
   mkmask)
      [ $# -ne 2 ] && usage "bad mkmask args"
      name="$1"; shift
      subj_mni_roi="$1"; shift
      [ ! -r "$subj_mni_roi" ] && echo "cannot find subject roi mni nii.gz '$subj_mni_roi'!" && exit 1
      # e.g. subj_mni_roi=mni_examples/empty_coords_737713.587918_MP_for_mni.txt_mni.nii.gz
      mkcoords/subjroimni2mniroi.bash $(basename $name .nii.gz).nii.gz $subj_mni_roi
      ;;
   view)
      [ $# -ne 2 ] && usage "need 3 args for view"
      subj="$1"; shift
      MASK="$1"; shift
      # eg. mask="ROI_mni_MP_20191004.nii.gz"
      [ ! -r $MASK ] && MASK="mkcoords/$MASK"
      [ ! -r $MASK ] && echo "no roi mask '$MASK'" && exit 1

      # make subject file
      mni_examples/warp_to_example_subjs.bash $MASK $subj

      subj_coord=mni_examples/scout_space/$(basename $MASK .nii.gz)/${subj}_scout_cm.txt
      [ ! -r "$subj_coord" ] && echo "failed to make $subj_coord! see mni_examples/warp_to_example_subjs.bash" && exit 1

      mlrun "coord_mover('$subj', 'roilist','tmp/roilist_labels.txt','subjcoords', '$subj_coord')"
      ;;
   mni)
      echo "why?"
      mlrun "coord_mover('','subjcoords','mkcoords/mni_ijk.txt','brain','mkcoords/slice_mni.nii')"
      ;;
   *)
      usage;;
esac


