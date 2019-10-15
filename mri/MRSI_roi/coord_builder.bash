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
$0 view SUBJ MASK
$0 mkmask MASKNAME mni_examples/SUBJ_MNI_ROI.nii.gz
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

mlrun(){ matlab -nodesktop -nosplash -r "try; $@; catch(e); disp(e); quit(); end"; }



action="$1"; shift
case "$action" in
   place)
      [ $# -lt 1 ] && usage "bad place args"
      subj="$1"; shift
      [ $# -gt 0 ] && n="$1" || n=24
      seq 1 $n|sed s/$/:/ > tmp/roilist_labels_$n.txt
      sed 's/:/\t50\t50/g' tmp/roilist_labels_$n.txt > tmp/empty_coords_$n.txt
      mlrun "coord_mover('$subj', 'roilist','tmp/roilist_labels_$n.txt','subjcoords', 'tmp/empty_coords_$n.txt')"
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
      [ $# -ne 3 ] && usage
      subj="$1"; shift
      n="$1"; shift
      mask="$1"; shift
      # eg. mask="ROI_mni_MP_20191004.nii.gz"
      [ ! -r $MASK ] && MASK=/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/$MASK 
      [ ! -r $MASK ] && echo "no roi mask $MASK" && exit 1

      # make subject file
      cd /Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/mni_examples
      ./warp_to_example_subjs.bash ../mkcoords/$MASK $subj
      cd -

      subj_coord=mni_examples/scout_space/$(basename $MASK)/${subj}_scout_cm.txt
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


