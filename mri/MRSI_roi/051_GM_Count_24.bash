#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
#  generate txt file with GM counts
#  20190509WF  init


ROILABELID=ROI_mni_MP_20191022
doneflag=finish_percentGM_24_$ROILABELID.flag
roi_gmpctout=percent_cnt_$ROILABELID.txt
#roi_gmpctout=roi_percent_cnt.txt
nroi=24
#74 53 50 1  11651_20190222 file.coord
awk '{print $5, $6}' txt/pos_24specs_20191102.txt|
 sort -u |
 while read ld8 f; do
   echo "# $ld8"
   aparcaseg="/Volumes/Hera/preproc/7TBrainMech_rest/FS/$ld8/mri/aparc+aseg.mgz"
   [ ! -r "$aparcaseg" ] && echo "no FS for $ld8, redo ../011_FS.bash" && continue

   coords_mprage="$(dirname $f)/coords_mprage.nii.gz"
   [ -z "$coords_mprage" -o ! -r $coords_mprage ] && echo "missing $coords_mprage for $f -- coord_building did not make?!" && continue

   test -d /Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI_roi/spectrum || mkdir $_
   cd $_

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
      resampled_gm=fs_gmmask_mprage_24.nii.gz
      [ ! -r $resampled_gm ] && AFNI_NIFTI_TYPE_WARN=NO \
         3dresample -inset fs_gmmask.nii.gz  -master $coords_mprage -prefix $resampled_gm -overwrite &&
         echo "wrong dims?! $(pwd)/fs_gmmask_mprage.nii.gz doesn't match, redone as $resampled_gm"
   fi
   # get roi stats: mean (percent) and voxel count. merge into single row, add id and spectrum type
   3dROIstats -quiet -nzvoxels -numROI $nroi -mask $coords_mprage $resampled_gm|
     tr $'\t' '\n'|
     sed 1d|
     paste - -|
     cat -n|
     sed "s/^/$ld8 $ROILABELID /" > $roi_gmpctout

   [ "$(awk 'END{print NR,NF }' $roi_gmpctout)" == "$nroi 5" ] &&
      echo "$(date) $0" > $doneflag ||
      echo "BAD ROI file $(pwd)/$roi_gmpctout!"

done
