# ROI based CSI extraction (cf. coord based in ../MRSI/)

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
  * Freesurfer parcilation (also needed for `label_csivox`)

## Notes
  * see `feh how_warped.png` (down arrow to zoom out)
  * see `/home/ni_tools/matlab_toolboxes/MRRC/readme.md` for using the GUI

## process
 0. `./000_setupdirs.bash 11323_20180316` creates `/Volumes/Hera/Projects/7TBrainMech/subjs/11323_20180316/slice_PFC/MRSI_roi/raw`
 0. `./001_inspect_setup.bash 11323_20180316` opens afni with warp rois loaded
 0. `./010_move_roi.bash 11323_20180316` interactively move rois
 0. `./020_matlab_subject.bash 11323_20180316` generates files to be used by LC model
 0. `./030_send_files.bash` - create a zip for given subjects to send to MRRC
 0. `./040_fetchFiles.bash` - stream all spreadsheet.csv in zip file(s) into one file
 0. `./041_merge_pos_val.R` - merge concatenated spreadsheets and roi number, label, and mni position
 0. `./050_ROIs.bash`       - for only coordinates in the merged data, create mni and anat space roi atlas masks
 0. `./051_GM_Count.bash`   - get fraction gm from anat roi mask

