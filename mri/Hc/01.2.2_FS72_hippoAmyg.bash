#!/usr/bin/env bash

# combine left and right HBT amygLabels
# right is +500 of left
# also see Makefile for txt/hc_fs_lut.txt (hc_lut.awk)
# depends on ants warp from 01.2_FS_to_HcScout.bash
#
#
# ambivalent about mgz->nii + 3dcalc HBT l,500+r being done here
# output file lives in FS7.2 directory without a clear pointer back to this script
#
# 20230201WF - init
#
verb(){ [ -n "${VERBOSE:-}" ] && warn "$*" || : ; }

FS72_hippoAmyg_one() {
   # combine HBT hemis and affine transform to scout space
   # hippoAmygLables_l-HBT_r-500HBT.nii.gz left in FS7.2 directory
   # ${ld8}_HBTlr500_scout.nii.gz put in spectrum/$MRID/FS_warp
   #FSdir like /Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/highres/11822_20210412/mri/
   local specdir="$1"; shift
   local fs_affine_l=("$specdir"/FS_warp/*_T1-HcScout_0GenericAffine.mat)
   fs_affine=${fs_affine_l[0]}
   [ -z "$fs_affine" -o ! -r "$fs_affine" ] &&
      echo "ERROR: $specdir/FS_warp has no affine. check 01.2_FS_to_HcScout.bash" &&
      return 1

   local ld8=$(ld8 "$fs_affine")
   fs_warpdir=$(dirname "$fs_affine")
   HBT_scout="$fs_warpdir/${ld8}_HBTlr500_scout.nii.gz"
   test -r "$HBT_scout" && verb "have $_" && return 0

   # 
   local FSdir_l=(/Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/*/$ld8/mri/)
   local FSdir=${FSdir_l[0]}
   [ -z "$FSdir" -o ! -r "$FSdir" ] &&
      echo "ERROR: $ld8 does not have a FS 7.2 dir (need for hippoamyg labels): ${FSdir_l[*]}" &&
      return 1

   hbts=("$FSdir/"[rl]h.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace.mgz)
   [ ${#hbts[@]} -ne 2 ] &&
      warn "# ERROR: $ld8 ${#hbts[@]} != 2 $FSdir/*hippoAmygLabels-T1.v21.HBT.FSvoxelSpacei* files!" &&
      return 1

   tmpd=$(mktemp -d /tmp/hc/fsconv-XXXXX || echo /tmp/hc/fsconv)
   for f in  "${hbts[@]}"; do
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

   dryrun
    niinote "$HBT_scout" \
    antsApplyTransforms -n NearestNeighbor \
      -t "$fs_affine" \
      -i "$combined_HBT" \
      -r "$fs_warpdir/${ld8}_HcScout_upsample.nii.gz" \
      -o "$HBT_scout"

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
      waitforjobs 4
   done
   wait
}
export -f FS72_hippoAmyg_one 

# if not sourced (testing), run as command
eval "$(iffmain "FS72_hippoAmyg_main")"

FS72_hippoAmyg_main_test() { #@test
   run FS72_hippoAmyg_main
   [[ $output =~ ".*" ]]
}
