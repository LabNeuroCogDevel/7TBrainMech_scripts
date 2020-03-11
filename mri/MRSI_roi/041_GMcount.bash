#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
#
#  generate txt file with GM counts
#
atlas=13MP20200207
nroi=$(3dBrickStat -max roi_locations/ROI_mni_$atlas.nii.gz)

#  20190509WF - init (now as atttic/051_GM_Count.bash)
#  20200311WF - use coords_mprage made by gui. keep in same folder as picked_coords.txt
#               specific to subj+coord picker
doneflag=.gmcounted # file w/date if finished this already
all_mprage=($(ls ../../../subjs/1*_2*/slice_PFC/MRSI_roi/$atlas/*/coords_mprage.nii.gz))
for coords_mprage in ${all_mprage[@]}; do
   ld8=$(ld8 $od)
   echo "# $ld8"
   aparcaseg="/Volumes/Hera/preproc/7TBrainMech_rest/FS/$ld8/mri/aparc+aseg.mgz"
   [ ! -r "$aparcaseg" ] && echo "no FS for $ld8, redo ../011_FS.bash" && continue

   cd $(dirname $coords_mprage)

   [ -r $doneflag ] && echo "finished $(pwd) $(cat $doneflag)" &&  continue
   # generate gm mask, put in dim's of mprage
   resampled_gm=fs_gmmask_mprage.nii.gz
   if [ ! -r $resampled_gm ]; then
      cmd="
       mri_binarize --i $aparcaseg --gm --o gmmask.mgz;
       mri_convert gmmask.mgz fs_gmmask.nii.gz;
       rm gmmask.mgz"
      eval "$cmd"
      3dNotes -h "$cmd" fs_gmmask.nii.gz
      AFNI_NIFTI_TYPE_WARN=NO \
         3dresample -inset fs_gmmask.nii.gz  -master $coords_mprage -prefix fs_gmmask_mprage.nii.gz -overwrite
   fi

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
     sed "s/^/$ld8 $atlas /" > $roi_gmpctout

   [ "$(awk 'END{print NR,NF }' $roi_gmpctout)" == "$nroi 5" ] &&
      echo "$(date) $0" > $doneflag ||
      echo "BAD ROI file $(pwd)/$roi_gmpctout!"

done
