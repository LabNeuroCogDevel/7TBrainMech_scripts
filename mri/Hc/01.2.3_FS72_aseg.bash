for f in spectrum/2*L*/FS_warp/gm_fs.nii.gz; do 
   # Get where aseg is by inspecting provenance of gm_fs file
   aseg72=$(3dNotes "$f" | grep -o '/Vol.*aseg.mgz')

   # Make sure we are able to extract aseg path
   if [ -z "$aseg72" -o ! -r "$aseg72" ]; then
       echo "Cannot find aseg in notes of $f"
       continue
   fi

   # Ensure aseg is from FS7.2
   if [[ ! "$aseg72" =~ FS7.2 ]]; then
       echo "$f is not from FS7.2 ($aseg72)!"
       continue
   fi

   # Derive subject ID and directories
   ld8=$(ld8 "$aseg72")
   FSwarpdir=$(dirname "$f")
   aseg_nii="$FSwarpdir/${ld8}_FSaseg72.nii.gz"

   # Convert aseg.mgz to NIfTI format (skip if it already exists)
   if [ ! -f "$aseg_nii" ]; then
       niinote "$aseg_nii" mri_convert "$aseg72" "$aseg_nii"
   else
       echo "Skipping mri_convert: $aseg_nii already exists."
   fi

   # Define the output file for the transformed aseg
   aseg_scout="$FSwarpdir/${ld8}_aseg72_scout.nii.gz"
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

