#!/usr/bin/env bash
#
# Make ${ld8}_aseg7.4.1-HcScout_HcOnly.nii.gz
# pull aseg into scout space and extract left and right Hc as a mask
#
#  0. follow anat.mat link to find CoregHC for scout and MPRAGE.nii
#  1. [3dresample] need to upsample scout for ants
#  2. [ants] use mprage for ants warp: from anat space to scout space
#  3. [ants] apply that affine transfrom (anat->scout) to aseg
#  4. [3dcalc] subset to just Hc rois (17,53)
#

set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
[ -v DRYRUN ] && DRYRUN=echo || DRYRUN=""

#
# reorganize files to for spectrum gui
# 20210825WF  init
# 20220304WF  allow for input args
getluna() { 
  # struggling with DB. just get these out
  # 20201113Luna1  could be 11700_20201113 or 11707_20201113
  hardcode="$(echo "
        11668  20220624Luna1
        11751  20220618Luna1
        11689  20210605Luna1
        11796  20210719Luna1
        11693  20211004Luna1
        11725  20211029Luna1
        11683  20211106Luna1
        11713  20211108Luna1
        11734  20220610Luna1 # is in db? but query fails 20230119
        11788  20230112Luna1 # is in db? but query fails 20230120
        11818  20221117Luna2
        11716  20221118Luna2
        11653  20180608Luna1
        11741  20190209Luna1
        11739  20190429Luna1
        11748  20190401Luna1 # also 11515
        11632  20191017Luna1
        11702  20230309Luna1 # 20230319. rushed, not sure why not in DB
        " \
     | grep "$1" |awk '{ print $1 }')"
   [ -n "$hardcode" ] && echo "$hardcode" && return 0

   lncddb "select e.id from enroll e join enroll m on e.pid=m.pid and e.etype='LunaID' and m.id like '$1%'"|
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
[[ $# -eq 0 || "$*" =~ "-h" ]] && echo "USAGE: $0 [all|missing|7TMRID]" && exit 1
case "$1" in
   all) 
     mapfile -t ANATS < <(find "$(pwd)"/spectrum/* -maxdepth 1 -name anat.mat -type f,l);;
   missing)
     ./to_place.bash |grep FS|sed 's:spectrum/::;s/ .*//'|xargs "$0";
     exit;;
   *)
     mapfile -t ANATS < <(build_anat "$@")
esac

# most coreg and siarray are in Recon. but a few are in Shim
for anat in "${ANATS[@]}"; do
   specdir=$(dirname "$anat")
   outdir=$specdir/FS_warp

   [[ $anat =~ 20[0-9]{6}L[Uu][Nn][Aa][1-9]? ]] || continue
   id="${BASH_REMATCH[*]}"
   # 20220316 - looks okay? 
   #  afni /Volumes/Hera/preproc/7TBrainMech_rest/MHT1_2mm/10173_20210830
   # but Recon isn't?
   # * FATAL ERROR: Can't open dataset /Volumes/Hera/Raw/MRprojects/7TBrainMech/20210830Luna1/Recon/CoregHC/20210830_122724MP2RAGEPTXTR60001mmisos046a1001.nii
   #[[ $id == 20210830Luna1 ]] && echo "# $id: bad mprage; skipping" && continue

   [[ $anat =~ 20[0-9]{6} ]] || continue
   yyymmdd="${BASH_REMATCH[*]}"

   # /Volumes/Hera/Raw/MRprojects/7TBrainMech/20210809Luna1/Recon/CoregHC
   # want to unlink
   ! test -r "$anat" && echo "bad file $anat" && continue
   anat_link="$(readlink -f "$anat")"
   anatdir=$(dirname "$(dirname "$anat_link")")


   # 20260330WFDW - hard code people with weird file organization
   #                idealy would fix file, but we have nested links. this is easier?
   case $anat in 
      *20181112Luna1*) anatdir="/Volumes/Hera/Raw/MRprojects/7TBrainMech/duplicate-folders-collected-20240328/20181112Luna1-processed/Recon_CSI/CoregHC/";;
   esac

   [ -z "$anatdir" -o "$anatdir" == "." ] &&
      echo "#ERROR: cannot fidn link dir from '$anat_link' ('$anat')!?" && continue
   t1=$(find -L "$anatdir" -maxdepth 1 -type f,l \( -iname '[^r]*MP*nii' -or -iname 'MP*nii' \) )
   sct=$(find -L "$anatdir" -maxdepth 1 -type f,l \( -iname '*SCOUT*.nii' -or -iname '*grefieldmappingMCxxB0map33*' -or -iname 'hcslice_e*.nii'  \) -not -iname '*_resize.nii' -print -quit)



   [ -z "$t1" ] && echo "#ERROR: $id: cannot find struct *MP*nii in '$anatdir' ($anat)" && continue
   [ -z "$sct" ] && echo "#ERROR: $id: cannot find scout *SCOUT*nii in '$anatdir'" && continue

   luna=$(getluna "$id"); ld8=${luna}_$yyymmdd
   [ -z "$luna" ] && echo "# ERROR: $id: cannot find luna id! maybe not in database yet? Will needs to update!" && continue
   FS=/Volumes/Hera/Projects/hippocampal_myelin/freesurfer7.4.1_long/sub-${luna}_ses-$yyymmdd.long.sub-${luna}/mri/aseg.mgz
   # 20220304 - okay to use low res if no original
   # 20260225 - skip if they don't have it
   [ ! -r "$FS" ] &&
      echo "# ERROR: $id/$ld8: cannot find '$FS'; may not have a mp2rage for FS7.4.1 \
         see /Volumes/Hera/Projects/hippocampal_myelin/freesurfer7.4.1_long/sub-${luna}_ses-$yyymmdd.long.sub-${luna}/mri" &&
      continue

   final_file=$outdir/${ld8}_aseg7.4.1-HcScout_HcOnly.nii.gz
   [ -r "$final_file" ] && echo "# have $final_file" && continue

   echo "# creating $final_file"
   ! test -d "$outdir" && $DRYRUN mkdir -p "$_"
   $DRYRUN cd "$outdir"

   FSnii=${ld8}_FSaseg7.4.1.nii.gz 
   test ! -r $FSnii && $DRYRUN niinote $FSnii mri_convert $FS $FSnii

   test -r ${ld8}_HcScout_upsample.nii.gz ||
      $DRYRUN 3dresample -dxyz 1 1 1 -inset $sct -rmode Cu -prefix $_ -overwrite
   prefix=${ld8}_T1-HcScout_
   test -r ${prefix}0GenericAffine.mat ||
      $DRYRUN niinote ${prefix}Warped.nii.gz \
      antsRegistrationSyNQuick.sh -f ${ld8}_HcScout_upsample.nii.gz -m $t1 -t r -o $prefix
   
   test -r ${ld8}_aseg7.4.1_scout.nii.gz ||
      $DRYRUN niinote $_\
         antsApplyTransforms -n NearestNeighbor \
          -t ${prefix}0GenericAffine.mat \
          -i $FSnii \
          -r ${ld8}_HcScout_upsample.nii.gz\
          -o $_

   $DRYRUN 3dcalc \
      -m ${ld8}_aseg7.4.1_scout.nii.gz\
      -expr 'amongst(m,17,53)' \
      -prefix $(basename $final_file) -overwrite 
done
