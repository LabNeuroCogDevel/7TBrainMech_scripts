#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
[ -v DRYRUN ] && DRYRUN=echo || DRYRUN=""

#
# reorganize files to for spectrum gui
# 20210825WF  init
# 20220304WF  allow for input args
getluna() {  lncddb "select e.id from enroll e join enroll m on e.pid=m.pid and e.etype='LunaID' and m.id like '$1%'"|
   sed 1q; }

build_anat(){
     for id in "$@"; do
       anat="$(pwd)/spectrum/$id/anat.mat"
       [ ! -r "$anat" ] &&
          echo "ERROR: $id missing '$anat'. rerun ./01.1_reorg_for_matlab_gui.bash" >&2 &&
          continue
       echo "$anat"
    done
}

# allow single 7TMRID input. much easier for debugging when something is missing
[[ $# -eq 0 || "$*" =~ "-h" ]] && echo "USAGE: $0 [all|7TMRID]" && exit 1
case "$1" in
   all) 
    mapfile -t ANATS < <(find "$(pwd)"/spectrum/* -maxdepth 1 -name anat.mat -type f,l);;
 *) mapfile -t ANATS < <(build_anat "$@")
esac

# most coreg and siarray are in Recon. but a few are in Shim
for anat in "${ANATS[@]}"; do
   specdir=$(dirname "$anat")
   outdir=$specdir/FS_warp

   [[ $anat =~ 20[0-9]{6}Luna[1-9] ]] || continue
   id="${BASH_REMATCH[*]}"
   [[ $id == 20210830Luna1 ]] && echo "# $id: bad mprage; skipping" && continue

   [[ $anat =~ 20[0-9]{6} ]] || continue
   yyymmdd="${BASH_REMATCH[*]}"

   # /Volumes/Hera/Raw/MRprojects/7TBrainMech/20210809Luna1/Recon/CoregHC
   # want to unlink
   anat_link="$(readlink -f "$anat")"
   anatdir=$(dirname "$(dirname "$anat_link")")

   [ -z "$anatdir" -o "$anatdir" == "." ] &&
      echo "#ERROR: cannot fidn link dir from '$anat_link' ('$anat')!?" && continue
   t1=$(find "$anatdir" -maxdepth 1 -type f,l \( -iname '[^r]*MP*nii' -or -iname 'MP*nii' \) )
   sct=$(find "$anatdir" -maxdepth 1 -type f,l -iname '*SCOUT*.nii' -not -iname '*_resize.nii'|sed 1q)
   [ -z "$t1" ] && echo "#ERROR: $id: cannot find struct *MP*nii in '$anatdir'" && continue
   [ -z "$sct" ] && echo "#ERROR: $id: cannot find scout *SCOUT*nii in '$anatdir'" && continue

   luna=$(getluna "$id"); ld8=${luna}_$yyymmdd
   [ -z "$luna" ] && echo "# ERROR: $id: cannot find luna id! maybe not in database yet? Will needs to update!" && continue
   FS=/Volumes/Hera/preproc/7TBrainMech_rest/FS/$ld8/mri/aseg.mgz
   # 20220304 - okay to use low res if no original
   [ ! -r "$FS" ] &&
     FS="/Volumes/Hera/preproc/7TBrainMech_rest/FS_lowres/$ld8/mri/aseg.mgz"
   [ ! -r "$FS" ] &&
      echo "# ERROR: $id/$ld8: cannot find '$FS' or ${FS/_lowres\//\/}! \
         see /Volumes/Hera/Raw/BIDS/7TBrainMech/sub-${ld8/_*/}/${ld8/*_/}/anat \
         run /Volumes/Hera/Projects/7TBrainMech/scripts/mri/FS/001_runlocal.bash" &&
      continue

   final_file=$outdir/${ld8}_aseg-HcScout_HcOnly.nii.gz
   [ -r "$final_file" ] && echo "# have $final_file" && continue

   echo "# creating $final_file"
   ! test -d "$outdir" && $DRYRUN mkdir -p "$_"
   $DRYRUN cd "$outdir"

   FSnii=${ld8}_FSaseg.nii.gz 
   test ! -r $FSnii && $DRYRUN niinote $FSnii mri_convert $FS $FSnii

   test -r ${ld8}_HcScout_upsample.nii.gz ||
      $DRYRUN 3dresample -dxyz 1 1 1 -inset $sct -rmode Cu -prefix $_ -overwrite
   prefix=${ld8}_T1-HcScout_
   test -r ${prefix}0GenericAffine.mat ||
      $DRYRUN antsRegistrationSyNQuick.sh -f ${ld8}_HcScout_upsample.nii.gz -m $t1 -t r -o $prefix
   
   test -r ${ld8}_aseg_scout.nii.gz ||
      $DRYRUN niinote $_\
         antsApplyTransforms -n NearestNeighbor \
          -t ${prefix}0GenericAffine.mat \
          -i $FSnii \
          -r ${ld8}_HcScout_upsample.nii.gz\
          -o $_

   $DRYRUN 3dcalc \
      -m ${ld8}_aseg_scout.nii.gz\
      -expr 'amongst(m,17,53)' \
      -prefix $(basename $final_file) -overwrite 
done
