#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

# make mni versions of all cis
# 20190730WF - init
for mdir in /Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/; do
   cd $mdir
   final_csi_mni=csi_pfc_mni.nii.gz
   [ -r $final_csi_mni ] && echo "skip $mdir" >&2 && continue
   csi=MRSI/all_csi.nii.gz
   pfc=slice_pfc.nii.gz
   warpmat=MRSI_roi/spectrum/slice_to_mprage.mat
   [ ! -r $csi -o ! -r $pfc ] && echo "$mdir: missing slice_pfc or all_csi!" >&2 && continue
   [ ! -r ppt1/template_brain.nii -o ! -r ppt1/mprage_warpcoef.nii.gz ] && echo "$mdir/ppt1: missing mprage preprocessing" >&2 && continue
   [ ! -r $warpmat ] && echo "$mdir/$warpmat DNE. need to run MRSI_ROI scripts (../MRSI_roi/050_ROIs.bash)" >&2 && continue
   labels="$(3dinfo -label $csi | sed 's/\[0\]//g;s/\.\?n\?i*|/ /g')"
   cmd="
      3dresample -inset $csi -master $pfc -prefix allcsi_tmp_large.nii.gz;
      applywarp -i allcsi_tmp_large.nii.gz -o $final_csi_mni -r ppt1/template_brain.nii -w ppt1/mprage_warpcoef.nii.gz  --premat=$warpmat;
      3drefit -relabel_all_str '$labels' $final_csi_mni;"
   echo -e "$(pwd)\n$cmd"
   eval $cmd
   [ -r allcsi_tmp_large.nii.gz ] && rm allcsi_tmp_large.nii.gz
   [ -r $final_csi_mni ] && 3dNotes -h "$0 $cmd" $final_csi_mni 
done
