#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
#  generate txt file with GM counts
#  20190509WF  init


ROILABELID=MPOR_20190425
for d in /Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI_roi/spectrum; do
   # check inputs
   ! [[ $d =~ [0-9]{5}_[0-9]{8} ]] && echo "no ld8 in $d" && continue
   ld8=$BASH_REMATCH
   aparcaseg="/Volumes/Hera/preproc/7TBrainMech_rest/FS/${ld8}/mri/aparc+aseg.mgz"
   [ ! -r $aparcaseg ] && echo "no FS for $ld8, redo ../011_FS.bash" && continue

   cd $d
   [ ! -r coords_mprage.nii.gz ] && echo "missing $d/coords_mprage.nii.gz; rerun ./050_ROIs.bash" && continue
   [ -r finish_percentGM.flag ] && echo "finished $(pwd) $(cat finish_percentGM.flag); redo: rm $(pwd)/finish_percentGM.flag" &&  continue
   if [ ! -r fs_gmmask_mprage.nii.gz ]; then
      # generate gm mask, put in dim's of mprage
      cmd="
       mri_binarize --i $aparcaseg --gm --o gmmask.mgz;
       mri_convert gmmask.mgz fs_gmmask.nii.gz;
       rm gmmask.mgz"
      eval "$cmd"
      3dNotes -h "$cmd" fs_gmmask.nii.gz

      AFNI_NIFTI_TYPE_WARN=NO \
         3dresample -inset fs_gmmask.nii.gz  -master coords_mprage.nii.gz -prefix fs_gmmask_mprage.nii.gz -overwrite
   fi
   # get roi stats: mean (percent) and voxel count. merge into single row, add id and spectrum type
   3dROIstats -quiet -nzvoxels -numROI 12 -mask coords_mprage.nii.gz  fs_gmmask_mprage.nii.gz|
     tr $'\t' '\n'|
     sed 1d|
     paste - -|
     cat -n|
     sed "s/^/$ld8 $ROILABELID /" > roi_percent_cnt.txt

   [ "$(awk 'END{print NR,NF }' roi_percent_cnt.txt)" == "12 5" ] &&
      echo "$(date) $0" > finish_percentGM.flag ||
      echo "BAD ROI file $(pwd)/roi_percent_cnt.txt!"
done
