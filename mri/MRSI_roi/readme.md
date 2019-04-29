# ROI based CSI extraction (cf. coord based in ../MRSI/)

## Deps
  * scout as nifti and t1 <-> mni 
  * co-registration (mprage -> slice) from `../MRSI/02_label_csivox.bash` has output like `17_7_MPRAGE` useful for gui

## Notes
  * see `feh how_warped.png` (down arrow to zoom out)
  * see `/home/ni_tools/matlab_toolboxes/MRRC/readme.md` for using the GUI

## process
 1. `./000_setupdirs.bash 11323_20180316` creates `/Volumes/Hera/Projects/7TBrainMech/subjs/11323_20180316/slice_PFC/MRSI_roi/raw`
 2. `./001_inspect_setup.bash 11323_20180316` opens afni with warp rois loaded
 3. `./010_move_roi.bash 11323_20180316` interactively move rois
 4. `./020_matlab_subject.bash 11323_20180316` generates files to be used by LC model
