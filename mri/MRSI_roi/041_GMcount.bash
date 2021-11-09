#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
#
#  generate txt file with GM counts
#
[ -v DRYRUN ] && DRYRUN=echo || DRYRUN=
writeto() { [ -z "$DRYRUN" ] && cat > $@ || echo "# would write to $@"; }

atlas=13MP20200207
roi_gmpctout=roi_percent_cnt_$atlas.txt
nroi=$(3dBrickStat -max roi_locations/ROI_mni_$atlas.nii.gz | sed 's/[ \t]*//g')

#  20190509WF - init (now as atttic/051_GM_Count.bash)
#  20200311WF - use coords_mprage made by gui. keep in same folder as picked_coords.txt
#               specific to subj+coord picker
doneflag=.gmcounted # file w/date if finished this already
all_mprage=($(ls $(cd ../../../;pwd)/subjs/1*_2*/slice_PFC/MRSI_roi/$atlas/*/coords_mprage.nii.gz))


# ONLY DO ONE ID (for testing)
env |grep -q '^ONLYID=' || ONLYID=""

for coords_mprage in ${all_mprage[@]}; do
   ld8=$(ld8 $coords_mprage)
   echo "# $ld8"
   [ -n "$ONLYID" -a "$ONLYID" != "$ld8" ] && continue
   aparcaseg="/Volumes/Hera/preproc/7TBrainMech_rest/FS/$ld8/mri/aparc+aseg.mgz"
   [ ! -r "$aparcaseg" ] && echo "no FS for $ld8, redo ../011_FS.bash" && continue

   cd $(dirname $coords_mprage)

   [ -r $doneflag ] && echo "finished $(pwd) $(cat $doneflag)" &&  continue
   [ -r $roi_gmpctout ] && echo "ERROR $(pwd): have $doneflag but not $roi_gmpctout!? inspect dir and remove done flag" && continue
   # generate gm mask, put in dim's of mprage
   resampled_gm=fs_gmmask_mprage.nii.gz
   if [ ! -r $resampled_gm ]; then
      cmd="
       mri_binarize --i $aparcaseg --gm --o gmmask.mgz;
       mri_convert gmmask.mgz fs_gmmask.nii.gz;
       rm gmmask.mgz"
      $DRYRUN eval "$cmd"
      $DRYRUN 3dNotes -h "$cmd" fs_gmmask.nii.gz
      AFNI_NIFTI_TYPE_WARN=NO \
         $DRYRUN 3dresample -inset fs_gmmask.nii.gz  -master $coords_mprage -prefix fs_gmmask_mprage.nii.gz -overwrite
   fi

   [ ! -r $resampled_gm -a -n "$DRYRUN" ] && echo "# DRYRUN: cannot write $roi_gmpctout w/o making $resampled_gm" && continue

   if [ $(3dinfo -ad3 -n4 $coords_mprage $(pwd)/fs_gmmask_mprage.nii.gz |sort -u |wc -l) -ne 1 ]; then
      echo "wrong dims?! $(pwd)/fs_gmmask_mprage.nii.gz doesn't match, redone as $resampled_gm"
      continue
   fi
   # get roi stats: mean (percent) and voxel count. merge into single row, add id and spectrum type
   3dROIstats -quiet -nzvoxels -numROI $nroi -mask $coords_mprage $resampled_gm|
     tr $'\t' '\n'|
     sed 1d|
     paste - -|
     cat -n|
     sed "s/^/$ld8 $atlas /" |writeto $roi_gmpctout

   awksize="$(awk 'END{print NR,NF }' $roi_gmpctout)"
   [ "$awksize" == "$nroi 5" ] &&
      echo "$(date) $0" |writeto $doneflag ||
      echo "BAD ROI file: '$awksize' != '$nroi 5'; $(pwd)/$roi_gmpctout!"

done
