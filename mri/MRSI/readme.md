# CSI voxel labeling

## output

* coregistration affine matrix
* LUT
* `*_csivoxel_*`


## data input
 * Freesurfer output (need mprage -> orig.mgz, aparc+aseg.mgz, wmparc.mgz)
 * B0 scout

## methods input
 * `csi_settings.json` - FOV, mat size, and thickness of B0 scout and CSI acquisition
 * `roi.txt` - table w/roi name, matter (gm/wm/nb), and freesurfer values to group for both aparc and wmpar parcellation niftis

## code dependencies
* matlab toolbox: `NIfTI` and `spm12`  
* `SPMcoreg.mat` (included) - coregistration settings for spm

## sequence

## Notes
* `RAS` matrix orientation!!
* spm coregisration is stochastic, repeat runs are not the same
* `compare_matout` validates changes in code 
   (max prob diff in all files for one comparison: .0027)


