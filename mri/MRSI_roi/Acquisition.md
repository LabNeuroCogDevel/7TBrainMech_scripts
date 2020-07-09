Magnetic Resonance Imaging/ Magnetic Resonance Spectroscopic Imaging

Magnetic resonance imaging (MRI) and H1-Magnetic resonance spectroscopic imaging (MRSI) were performed at University of Pittsburgh Medical Center Magnetic Resonance Research Center using a 7.0Tesla (7T) Siemens whole-body scanner (Siemens Medical Solutions, Erlangen, Germany).
Structural images for use in parcellation and aligning were obtained using an MP2RAGE sequence (***1 mm isotropic resolution, TR/TE/flip angle 1/ flip angle 2: 26000 ms/2.47 ms/40/50 ***).

MRSI data was acquired using a J-refocused spectroscopic imaging sequence (Pan et al., 1996; Pan et al., 2010) (***TE/TR = 17/1500ms***) with RF based outer-volume suppression (Hetherington et al., 2010) and an 8x2 1H transceiver array using 8 independent RF channels (Avdievich, 2011).
High degree B0 shimming was used to improve field homogeneity (Pan et al., 2012).
***One slice was acquired (10mm thick 24x24 encodes across a FOV of 216x216 mm <1cc effective resolution)***.
The slice was axially positioned to include DLPFC (BA46/BA9).
In order to minimize individual variability in brain morphology and slice positioning, a program developed in-house (https://github.com/LabNeuroCogDevel/slice_warp_gui) was used during acquisition to map an oblique slice atlas into the subject’s native space in real-time.
This allowed for that image to be uploaded to the scanner and used for placement.


The centers of the reconstructed spectroscopic voxels use for this analysis were defined using a custom atlas of 13 regions of interest (ROI) followed by manual adjustments in roughly 6 steps (https://github.com/LabNeuroCogDevel/7TBrainMech_scripts/blob/master/mri/MRSI_roi/000_setupdirs.bash).
(1) The structural image was registered to the spectroscopy scout (linear, fsl's flirt) and to the MNI 152 2009c asym template (non-linear ANTs, convert3d).
(2) The nonlinear warp coefficients (MNI->T1) and affine transform (T1->scout) were combined to align the ROIs in template space with each scout, providing an initial center of mass estimate.
(3) Additionally, Freesurfer was used to generate a white matter mask that was then also aligned to the scout with the same affine transformation. The high resolution structural, WM mask, and initial region estimates were then all relative to the spectroscopy acquisition.
(4) Individual voxel centers for each region of interest (ROI) were adjusted using a program developed in-house (https://github.com/LabNeuroCogDevel/MRSIcoord.py/tree/master/matlab).
(5) Voxel positions were selected in order to optimize spectral quality upon visual inspection (**Cite Hoby's matlab program**) and maximize fraction of gray matter.
(6) To ensure adjusted position was still within the region of interest, a 9mmx9mmx10mm sphere centered at the adjusted coordinate was warped from the spectroscopy space to MNI space and inspected using the Talairach-Tournoux atlas as provided by AFNI’s whereami (Cox, 1996).

Voxels were reconstructed at identfied loci using in-house software (Hetherington, 2007 neurolog paper?). Metabolite concentrations were then quantified in reference to creatine (Cr) using LCModel (Provencher, 2001). Spectra were excluded if the Cramer-Rao Lower Bound (CRLB) for NAA, Cr, or Cho was > 10 (representing poor quality spectra) or if MM/Cr was > 3 (representing a large macromolecule contribution that could distort metabolite quantification). Individual metabolites were excluded if their Cramer-Rao Lower Bounds (CRLBs) were > 20.
