# CSI voxel labeling

## overview
This repo uses MRRC (Victor) Matlab code to label 24x24 csi pixel/voxel grid with upsampled 1mm^3 Freesurfer parcilation and assign LC model spreadsheet molecule values to FS regions of interest.
The code is repurposed to do the same for an MNI ROI atlas (registered from MNI to slice space via fsl's inversewarp on preprocessMprage's warpcoef).

Each pixel is given a percentage (via hanning filter?) overlap with each ROI. ROI pixel labeling is winner-take-all. 

N.B! 
Every pixel/voxel on the slice 24x24 plane is labeled as an ROI even when none are reasonable.
This is esp. weird for GM/WM identification. If both WM & GM have near 0 percentages, code still picks one. Use the tissue mask!


## output
* Freesurfer ROIS
   * `MRSI/all_probs.nii.gz`  - percent in FS ROI 
   * `MRSI/all_csi.nii.gz`    - CSI LC Model values, one brick per molecule value or CRLB
   * `MRSI/mprage_in_slice.nii.gz` - anatomical registred (linear warped) into slice orientation
   * `MRSI/2d_csi_ROI/*lut*`     - lookup table
   * `MRSI/parc_group/mprage_to_scout_*txt` - SPM coregistration affine matrix 

* MNI ROI Atlas
   * `atlas_roi/func_atlas.mat` - matlab struct of atlas roi labels

### ROI name and number
#### Freesurfer based parcilation
from `roi.txt`

```
cat /Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI/2d_csi_ROI/ParcelCSIvoxel_lut.txt | sort -nu
1   CAcing            CACGM
2   PIcing            PICGM
3   RAcing            RACGM
4   abnormal          AGM
5   basal_ganglia     BGA
6   frontal           FGM
7   insula            IGM
8   occipital         OGM
9   parietal          PGM
10  subcortical       SCGM
11  temporal_lateral  TLGM
12  temporal_medial   TMGM
13  thalamus          THA
```

#### Atlas ROI 
from `slice_rois_mni_extent.nii.gz`
see `afni /Volumes/Hera/Projects/7TBrainMech/subjs/11641_20180510/slice_PFC/{mprage_in_slice,roi_slice}.nii.gz`

## glossary
 * [Freesurfer](https://surfer.nmr.mgh.harvard.edu) -> anatomical segmentation
 * [LCModel](http://s-provencher.com/lcm-manual.shtml) [(ref)](https://onlinelibrary.wiley.com/doi/epdf/10.1002/mrm.1910300604) -> spreadsheet.csv
    * %SD == CRLB == Cramer-Rao lower bounds == estimated standard devation (model fit)
    > %SD≈20% indicates that only changes of about 40% can be detected with reliability, e.g., the approximate doubling of Gln/Glu in several pathologies. A %SD<20% has been used by many as a very rough criterion for estimates ofacceptable reliability. However, it is only a subjective indication, not a rigorous limit.

 * FSL: flirt applywarp inversewarp -> registration = warping
 * MRSI == CSI
 * preprocessMprage
 * Matlab:[SPM](https://www.fil.ion.ucl.ac.uk/spm/)
 * Files
    * `r*nii` - Nifti files that start with `r` are registered to scout/slice.

## data input
Initial Freesurfer labeling
 * Freesurfer output (need mprage as orig.mgz, aparc+aseg.mgz, wmparc.mgz)
 * B0 scout
 * spreadsheet.csv: 24x24 pixel melted matrix of 9x9x10mm CSI LC Model values for each molecule and CRLB

Additionally, for atlas ROIs
 * a priori ROI atlas
 * preprocessMprage's warpcoef

## methods input
 * `csi_settings.json` - FOV, mat size, and thickness of B0 scout and CSI acquisition
 * `roi.txt` - table w/roi name, matter (gm/wm/nb), and freesurfer values to group for both aparc and wmpar parcellation niftis

## code dependencies
* matlab toolbox: `NIfTI` and `spm12`  
* `SPMcoreg.mat` (included) - coregistration settings for spm

## Notes
* `RAS` matrix orientation!!??
* spm coregisration is stochastic, repeat runs are not the same
* `compare_matout` validates changes in code 
   (max prob diff in all files for one comparison: .0027)


