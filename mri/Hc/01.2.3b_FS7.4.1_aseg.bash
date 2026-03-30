#!/usr/bin/env bash
#
# warp placement files created by 04_fslabels.bash (scout HC) to MNI
# to compare converage
#
#
# convert_xfm -omat "$to_t1_fsl" -inverse "$to_hc_fsl"
# convert_xfm -omat "$hc_to_mni_mat" -concat "$t1_to_mni_mat" "$hc_to_t1"
# applywarp  --premat="$to_t1_fsl" -r $mni_ref -w "$to_mni" --interp=nn -i "$f" -o "$mni_out" 
#
# 20250403WF - init
#

for f in spectrum/2*L*/FS_warp/gm_fs7.4.1.nii.gz; do 
   # Get where aseg is by inspecting provenance of gm_fs file
   aseg74=$(3dNotes "$f" | grep -o '/Vol.*aseg.mgz')

   # Make sure we are able to extract aseg path
   if [ -z "$aseg74" -o ! -r "$aseg74" ]; then
       echo "Cannot find aseg in notes of $f"
       continue
   fi

   # Ensure aseg is from FS7.4.1
   if [[ ! "$aseg74" =~ FS7.4.1 ]]; then
       echo "$f is not from FS7.4.1 ($aseg74)!"
       continue
   fi

   # Derive subject ID and directories
   ld8=$(ld8 "$aseg74")
   FSwarpdir=$(dirname "$f")
   aseg_nii="$FSwarpdir/${ld8}_FSaseg7.4.1.nii.gz"

   # Convert aseg.mgz to NIfTI format (skip if it already exists)
   if [ ! -f "$aseg_nii" ]; then
       niinote "$aseg_nii" mri_convert "$aseg74" "$aseg_nii"
   else
       echo "Skipping mri_convert: $aseg_nii already exists."
   fi

   # Define the output file for the transformed aseg
   aseg_scout="$FSwarpdir/${ld8}_aseg7.4.1_scout.nii.gz"
   transform_mat="${FSwarpdir}/${ld8}_T1-HcScout_0GenericAffine.mat"
   reference_img="${FSwarpdir}/${ld8}_HcScout_upsample.nii.gz"

   # Apply ANTs transformation (skip if output already exists)
   if [ ! -f "$aseg_scout" ]; then
       niinote "$aseg_scout" antsApplyTransforms -n NearestNeighbor -t "$transform_mat" -i "$aseg_nii" -r "$reference_img" -o "$aseg_scout"
   else
       echo "Skipping antsApplyTransforms: $aseg_scout already exists."
       continue
   fi
done

