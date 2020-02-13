#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)

#
# "build"/place coordinates and inspect them on different subjects
#  20191015WF  init
#  20191017WF  rename options to sphere and blob

usage() {
   [ $# -gt 1 ] && msg="$@!\n" || msg=""
cat <<HEREDOC 
${msg}USAGE:
 $0 place SUBJ [NUMBER=24]
 $0 mni-subj-blob subj coordfile ppt1dir slice_dir outdir   # run by coord_mover.m
 $0 mni-cm-sphere MASKNAME mni_examples/SUBJ_MNI_ROI.nii.gz # temp file for coord_mover.m
 $0 view SUBJ MASKNAME
 $0 mni

EXAMPLE:
 # 1. run coord_mover.m to place roi coordinates on a single subject in slice space
 $0 place 11734_20190128

 # 2. click "mni" warps subject square rois into mni, runs
 #  mni_examples/warps/ 
 # $0 mni-subjblob <generated_coord> <t1_dir> <slice_dir> mni_examples/ 

 # 3. new mni sphers from cm of subj-in-mni rois. explictly named
 $0 mni-cm-sphere ROI_mni_MP_20191004.nii.gz mni_examples/empty_coords_737713.587918_MP_for_mni.txt_mni.nii.gz

 # 4. view mni coords as placed in a subjects slice space using matlab gui coord_viewer
 #  mni_examples/scout_space/
 $0 view 10129_20180917 ROI_mni_MP_20191004.nii.gz

 # x. open coord_mover on an mni brain with z-coord unlocked. not currently useful
 $0 mni
HEREDOC
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
      [ $# -gt 0 ] && n="$1" || n=13
      echo $n roi_num
      case $n in 
         24)
            roi_list="tmp/labels_MP20191015.txt"
            coord_list=tmp/MProi20191015.txt
            [ ! -r coord_list ] && seq 1 $n|sed 's/$/\t50\t50/' > $coord_list
            ;;
         13)
            roi_list="roi_locations/labels_13MP20200207.txt"
            coord_list="tmp/MProi20200207.txt"
            [ ! -r $coord_list ] && seq 1 $n|sed 's/$/\t50\t50/' > $coord_list
            ;;
         18)
            roi_list="tmp/labels_18MP20200117.txt"
            coord_list="tmp/MProi20200117.txt"
            [ ! -r $coord_list ] && seq 1 $n|sed 's/$/\t50\t50/' > $coord_list
            ;;
         *)
            roi_list=tmp/roilist_labels_$n.txt
            coord_list=tmp/empty_coords_$n.txt
            seq 1 $n|sed s/$/:/ > $roi_list
            sed 's/:/\t50\t50/g' $roi_list > $coord_list
            ;;
      esac
      mlrun "sf=autosid3('$subj'); [f, crd]=coord_mover('$subj', 'roilist','$roi_list','subjcoords', '$coord_list')"
      ;;
   mni-subjblob)
      # run from matlab. generate squares from coords positioned interatively in matlab on subject scout. warp to mni
      # only here for lookup/reference - run from subjcoord2mni.bash in coord_mover.m
      ./subjcoord2mni.bash $@
      ;;
   mni-cm-sphere)
      # get cm from mni-subjblob. generates spheres there.
      [ $# -ne 2 ] && usage "bad mkmask args"
      name="$1"; shift
      subj_mni_roi="$1"; shift
      [ ! -r "$subj_mni_roi" ] && echo "cannot find subject roi mni nii.gz '$subj_mni_roi'!" && exit 1
      # e.g. subj_mni_roi=mni_examples/empty_coords_737713.587918_MP_for_mni.txt_mni.nii.gz
      ./subjroimni2mniroi.bash $(basename $name .nii.gz).nii.gz $subj_mni_roi
      ;;
   view)
      [ $# -ne 2 ] && usage "view needs 2 args! subj and mask, not '$*' "
      subj="$1"; shift
      MASK="$1"; shift
      # eg. mask="ROI_mni_MP_20191004.nii.gz"
      [ ! -r $MASK ] && MASK="mkcoords/$MASK"
      [ ! -r $MASK ] && echo "no roi mask '$MASK'" && exit 1

      # make subject file
      mni_examples/warp_to_example_subjs.bash $MASK $subj

      subj_coord=mni_examples/scout_space/$(basename $MASK .nii.gz)/${subj}_scout_cm.txt
      [ ! -r "$subj_coord" ] && echo "failed to make $subj_coord! see mni_examples/warp_to_example_subjs.bash" && exit 1

      nroi=$(awk 'END{print $1}' $subj_coord)
      case $nroi in
         13) roi_list="roi_locations/labels_13MP20200207.txt";;
         18) roi_list="tmp/labels_18MP20200117.txt";;
         24) roi_list="tmp/labels_MP20191015.txt";;
         *) echo "dont know what tmp/labels_* roilist to pick when nroi=$nroi (cnt from last line in $subj_coord)"; exit 1;;
      esac
      mlrun "coord_mover('$subj', 'roilist','$roi_list','subjcoords', '$subj_coord')"
      ;;
   mni)
      echo "why?"
      mlrun "coord_mover('','subjcoords','mkcoords/mni_ijk.txt','brain','mkcoords/slice_mni.nii')"
      ;;
   *)
      usage;;
esac


