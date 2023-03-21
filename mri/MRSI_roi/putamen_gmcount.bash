#!/usr/bin/env bash

#  20230320WF - copyed from ./041_GMcount.bash but can be a lot simipler

check_coords(){
   if [ "$(3dinfo -ad3 -n4 "$@" |sort -u |wc -l)" -ne 1 ]; then
      warn "wrong dims?! $* doen't match [in $PWD]"
      return 1
   fi
   return 0
}
resample_gm(){
   local coords_mprage=${1:?mprage coord file}
   cd "$(dirname "$coords_mprage")" || return 1

   local ld8="$(ld8 "$coords_mprage")"
   test -r fs_gmmask_mprage.nii.gz && return 0
   fs="/Volumes/Hera/preproc/7TBrainMech_rest/FS/$ld8/mri/aparc+aseg.mgz"
   ! test -r "$fs" && warn "ERROR: $ld8: missing $fs. run FS" && return 1
   cmd="mri_binarize --i $fs --gm --o gmmask.mgz;
       mri_convert gmmask.mgz fs_gmmask.nii.gz;
       rm gmmask.mgz"
   if ! test -r fs_gmmask.nii.gz; then
      dryrun eval "$cmd"
      dryrun 3dNotes -h "$cmd" fs_gmmask.nii.gz
   fi
   dryrun 3dresample -inset fs_gmmask.nii.gz -master "$coords_mprage" -prefix fs_gmmask_mprage.nii.gz
}

roi_single(){
   local coords_mprage=${1:?mprage coord file}
   ld8=$(ld8 "$coords_mprage")
   #resampled_gm="$(dirname "$coords_mprage")"/fs_gmmask_mprage.nii.gz
   resample_gm "$coords_mprage" || return 1
   resampled_gm="fs_gmmask_mprage.nii.gz"
   #! test -s "$resampled_gm" && warn "$ld8: missing $resample_gm: maybe rerun ./041_GMcount.bash" && return 1
   check_coords "$coords_mprage" "$resampled_gm" || return 2

   [ -v DRYRUN ] && warn "# roistats on -mask $coords_mprage $resampled_gm" && return 0
   3dROIstats -quiet -nzvoxels -numROI 2 -mask "$coords_mprage" "$resampled_gm" |
        tr $'\t' '\n'|
        sed 1d|
        paste - -|
        cat -n|
        sed "s/^/$ld8 putamen2 /"  
}

roi_all(){
   all_mprage=( $(ls "$(cd ../../../;pwd)"/subjs/1*_2*/slice_PFC/MRSI_roi/putamen2/*/coords_mprage.nii.gz))
   echo "# ${#all_mprage[@]} coords_mprage.nii.gz files for putamen"
   for coords_mprage in "${all_mprage[@]}"; do
      # dont write if already have
      [ -r txt/putamen_gm.csv ] &&
        grep -q "$(ld8 "$coords_mprage")" txt/putamen_gm.csv && continue

      roi_single "$coords_mprage" || :
   done | drytee txt/putamen_gm.csv
   return 0
}

eval "$(iffmain roi_all)"
