#!/usr/bin/env bash

# combine left and right HBT amygLabels
# right is +500 of left
# also see Makefile for txt/hc_fs_lut.txt (hc_lut.awk)
# depends on ants warp from 01.2.1_FS_to_HcScout.bash
#
#
# ambivalent about mgz->nii + 3dcalc HBT l,500+r being done here
# output file lives in FS7.2 directory without a clear pointer back to this script
#
# 20230201WF - init
#
verb(){ [ -n "${VERBOSE:-}" ] && warn "$*" || : ; }
find_affine(){
   local specdir="$1"; shift
   local fs_affine_l=("$specdir"/FS_warp/*_T1-HcScout_0GenericAffine.mat)
   fs_affine=${fs_affine_l[0]}
   [ -z "$fs_affine" -o ! -r "$fs_affine" ] &&
      warn "ERROR: $specdir/FS_warp has no affine '$PWD/$fs_affine'. check ./01.2.1_FS_to_HcScout.bash $(basename "$specdir")" &&
      return 1
   echo "$fs_affine"
}
find_fsdir(){
   local ld8="$1" 
   local FSdir_l=(/Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/*/$ld8/mri/)
   local FSdir=${FSdir_l[0]}
   [ -z "$FSdir" -o ! -r "$FSdir" ] &&
      warn "ERROR: $ld8 does not have a FS 7.2 dir (need for hippoamyg labels): ${FSdir_l[*]}. see '../FS/001c_FreeSurfer7.2.bash $ld8'" &&
      return 1
   test ! -r "$FSdir/aseg.mgz"  && 
      warn "ERROR: $ld8 FS did not finish (cant read '$_')!" && return 1
   echo "$FSdir"
}

FS72_hippoAmyg_one() {
   # combine HBT hemis and affine transform to scout space
   # hippoAmygLables_l-HBT_r-500HBT.nii.gz left in FS7.2 directory
   # ${ld8}_HBTlr500_scout.nii.gz put in spectrum/$MRID/FS_warp
   #FSdir like /Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/highres/11822_20210412/mri/
   local specdir="$1"; shift
   local fs_affine fs_warpdir FSdir
   fs_affine=$(find_affine "$specdir") || return $?
   local ld8="$(ld8 "$fs_affine")"
   
   fs_warpdir=$(dirname "$fs_affine")
   HBT_scout="$fs_warpdir/${ld8}_HBTlr500_scout.nii.gz"
   test -r "$HBT_scout" && verb "have $_" && return 0

   FSdir=$(find_fsdir "$ld8") || return $?

   # 20230213
   # also want
   # lh.hippoAmygLabels-T1.v21.CA.FSvoxelSpace.mgz

   hbts=("$FSdir/"[rl]h.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace.mgz)
   [ ${#hbts[@]} -ne 2 ] &&
      warn "# ERROR: $ld8 ${#hbts[@]} != 2 $FSdir/*hippoAmygLabels-T1.v21.HBT.FSvoxelSpacei* files! see /Volumes/Hera/Projects/7TBrainMech/scripts/mri/FS/020_segHA.bash" &&
      return 1

   tmpd=$(mktemp -d /tmp/hc/fsconv-XXXXX || echo /tmp/hc/fsconv)
   for f in "${hbts[@]}"; do
      out=$tmpd/$(basename "$f" .mgz).nii.gz
      dryrun niinote "$out" mri_convert "$f" "$out"
   done

   combined_HBT="$FSdir"/hippoAmygLables_l-HBT_r-500HBT.nii.gz
   dryrun 3dcalc \
      -l "$tmpd/lh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace.nii.gz" \
      -r "$tmpd/rh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace.nii.gz" \
      -expr 'extreme(l,r+500*step(r))' \
      -prefix "$combined_HBT"
   rm -r "$tmpd"

   # add reference to this script
   3dNotes -h "# $0" "$combined_HBT"

   dryrun \
    niinote "$HBT_scout" \
    antsApplyTransforms -n NearestNeighbor \
      -t "$fs_affine" \
      -i "$combined_HBT" \
      -r "$fs_warpdir/${ld8}_HcScout_upsample.nii.gz" \
      -o "$HBT_scout"

}

FS72_gm_one() {
   local specdir="$1"; shift
   local fs_affine fs_warpdir FSdir
   fs_affine=$(find_affine "$specdir") || return $?
   local ld8="$(ld8 "$fs_affine")"
   
   fs_warpdir=$(dirname "$fs_affine")
   gm_scout="$fs_warpdir/${ld8}_gm_scout.nii.gz"
   test -r "$gm_scout" && verb "have $_" && return 0

   FSdir=$(find_fsdir "$ld8") || return $?

   gm_fs=$fs_warpdir/gm_fs.nii.gz
   dryrun niinote "$gm_fs" \
      mri_binarize --gm \
      --i "$FSdir/aseg.mgz" \
      --o "$gm_fs"

   #gm_t1=$fs_warpdir/gm_t1.nii.gz
   #3dresample  -master "" -inset "$gm_fs" --prefix "$gm_fs"
   # add reference to this script

   dryrun \
    niinote "$gm_scout" \
    antsApplyTransforms -n NearestNeighbor \
      -t "$fs_affine" \
      -i "$gm_fs" \
      -r "$fs_warpdir/${ld8}_HcScout_upsample.nii.gz" \
      -o "$gm_scout"
}



FS72_hippoAmyg_main(){
   [ $# -eq 0 ] &&
      echo "USAGE: $0 [all|spectrum/20180216Luna2]" &&
      exit 1

   [ "$1" == "all" ] &&
      FILES=(spectrum/2*/) ||
      FILES=("$@")

   for specdir in "${FILES[@]}"; do
      verb "$specdir"
      dryrun FS72_hippoAmyg_one "$specdir" & # || :
      FS72_gm_one "$specdir" &
      waitforjobs -j 4
   done
   wait
}
export -f FS72_hippoAmyg_one find_affine find_fsdir FS72_gm_one

# if not sourced (testing), run as command
eval "$(iffmain "FS72_hippoAmyg_main")"

find_fsdir_test() { #@test
   local output status
   run find_fsdir 11711_20181119
   [[ $status -eq 0 ]]
   [[ $output =~ .*FS.* ]]

   run find_fsdir 11711_20180000
   echo "s: $status"
   [[ $status -eq 1 ]]
}
find_affine_test() { #@test
   run find_affine spectrum/20180216Luna2/
   [[ $status -eq 0 ]]
   [[ $output =~ FS_warp/.*_T1-HcScout_0GenericAffine.mat ]]
}
