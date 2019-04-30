# CSI voxel labeling

## overview
Use MRRC (Victor) Matlab code to convert LC model spreadsheet output (24x24 pixel matrix of 9x9x10mm voxels) to upsampled 1mm^3 Freesurfer ROI parcilation.
Identifies percentage in roi and csi value (for each molecule) in 1mm nifti as well as matlab matricies.
ROI pixel labeling is winner take all of best percentage. WM/GM labeling is particularly weird because of this (if both near 0, picks GM). Use tissue mask!

## output
* `all_probs.nii.gz`  - percent in ROI 
* `all_csi.nii.gz`  
* `mprage_in_slice.nii.gz`
* `2d_csi_ROI/*lut*`
* coregistration affine matrix


## data input
 * Freesurfer output (need mprage as orig.mgz, aparc+aseg.mgz, wmparc.mgz)
 * B0 scout

## methods input
 * `csi_settings.json` - FOV, mat size, and thickness of B0 scout and CSI acquisition
 * `roi.txt` - table w/roi name, matter (gm/wm/nb), and freesurfer values to group for both aparc and wmpar parcellation niftis

## code dependencies
* matlab toolbox: `NIfTI` and `spm12`  
* `SPMcoreg.mat` (included) - coregistration settings for spm

## sequence

## Notes
* `RAS` matrix orientation!!??
* spm coregisration is stochastic, repeat runs are not the same
* `compare_matout` validates changes in code 
   (max prob diff in all files for one comparison: .0027)


