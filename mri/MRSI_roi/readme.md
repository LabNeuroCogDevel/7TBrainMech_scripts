# Coordinate/ROI based CSI extraction (cf. grid based FS+ROI in ../MRSI/)

```
mni roi -> slice row+col center -> sepectrum -> concentration
                               \-> mprage roi -> gm percentage
                                             \-> mni roi -> restingstate concectivity
```

1. We generate roi center coordinates for each roi and each subject
   * use our preproces pipeline outputs to warp rois into subject space, get center of mass
   * use `coord_mover.m` to reposition by hand
2. With SI.ARRAY scanner output, we generate a spectrum for each coordinate using `SVR1H2015.fig`
3. Each spectrum is sent to the MRRC and modeled with LC Model, a `spreadsheet.csv` is returned (in zip) with concentration values for molecules (e.g. GABA, Glu)
4. ROI masks (ANAT & MNI) are created with the coordinates used in the returned model

## Deps
  * scout as nifti and t1 <-> mni 
  * co-registration (mprage -> slice) from `../MRSI/02_label_csivox.bash` has output like `17_7_MPRAGE` useful for gui
  * Freesurfer parcilation (also needed for `label_csivox`) for registred gray matter (`r*GM*`) also from  `../MRSI/` (used to give percent GM in coord mover)

## process (20200114, 24 rois)
 0. `./000_setupdirs.bash 11323_20180316`
 1. `./coord_builder.bash view 11323_20180316 ROI_mni_MP_20191004.nii.gz`
 2. `f = mkspectrum('11323_20180316'); mkspectrum_roi(f); mkspectrum_roi(f, 12);` using ` ./mni_examples/warps/*/*/coords_rearranged.txt`
 3. `./040_fetchFiles.bash` -- edit to use newest zip and rename prefix
 4. `./050_ROIs.bash` - see blow for explination
 5. `./051_GM_Count_24.bash` 
 6. `./052_merge_GM_Count_24.R`
 
## process (12 rois)
 0. `./000_setupdirs.bash 11323_20180316` creates `Projects/7TBrainMech/subjs/11323_20180316/slice_PFC/MRSI_roi/raw` with links to files needed by the spectrum GUI and `slice_roi_MPOR20190425_CM_11323_20180316_16.txt`, the  center of mass of rois after `mni->t1->slice` warp
 0. `./001_inspect_setup.bash 11323_20180316` opens afni with warp rois loaded
 0. `./010_move_roi.bash 11323_20180316` interactively move rois. input is center of mass from `000_setupdirs.bash`
 ![mover screenshot](./img/coord_mover.png?raw=True)
 0. `./020_matlab_subject.bash 11323_20180316` generates files to be used by LC model -- autopopulates spectrum GUI
 ![mover screenshot](./img/spectrum_ml.png?raw=True)
 0. `./030_send_files.bash` - create a zip for given subjects to send to MRRC
 0. `../001_rsync_MRSI_from_box.bash` - to get new MRSI zip files
 0. `./040_fetchFiles.bash` - stream all spreadsheet.csv in zip file(s) into one file -- *EDIT* to include more zip files
 0. `./041_merge_pos_val.R` - merge concatenated spreadsheets and roi number, label, and mni position
 0. `./050_ROIs.bash`       - for only coordinates in the merged data, create mni and anat space roi atlas masks
 0. `./051_GM_Count.bash`   - get fraction gm from anat roi mask

#### Button click order
 0. load, load, load
 0. Reorient slice
 0. WritePositions (second write)
 0. IFFT
 0. Recon Coords
 0. enter, enter

### Directory initialization
`Projects/7TBrainMech/subjs/11323_20180316/slice_PFC/MRSI_roi/raw` after `./000_setupdirs.bash 11323_20180316` has these important files

```
 gm_sum.nii.gz
 slice_roi_MPOR20190425_CM_11323_20180316_16.txt
 mprage_middle.mat@  --> Projects/7TBrainMech/subjs/11323_20180316/slice_PFC/MRSI/struct_ROI/17_7_FlipLR.MPRAGE
 rorig.nii@          --> Projects/7TBrainMech/subjs/11323_20180316/slice_PFC/MRSI/parc_group/rorig.nii
 seg.7@              --> Projects/7TBrainMech/subjs/11323_20180316/slice_PFC/MRSI/struct_ROI/17_7_FlipLR.MPRAGE
 siarray.0.1@        --> Raw/MRprojects/7TBrainMech/20180316Luna1/CSIDLPFC/siarray.0.1
 siarray.1.1@        --> Raw/MRprojects/7TBrainMech/20180316Luna1/CSIDLPFC/siarray.1.1
```

## Notes
  * see `/home/ni_tools/matlab_toolboxes/MRRC/readme.md` for using the MRRC spectrum GUI
  * see `feh how_warped.png` (down arrow to zoom out)
 ![mover screenshot](./img/how_warped.png?raw=True)

### bad warps!?
20191126: somewhere along the way some of flirt's `mprage_to_slice.mat` do not match what they should!
see `mni_examples/fsl6_mprage_to_slice/` and `../MRSI/txt/warp_diffs.txt`
 `/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/20191118_badwarps.bash`
 `/Volumes/Hera/Projects/7TBrainMech/subjs/11656_20180607/slice_PFC/example_ants.bash`
