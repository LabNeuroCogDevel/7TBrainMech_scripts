Magnetic Resonance Imaging/ Magnetic Resonance Spectroscopic Imaging

Magnetic resonance imaging (MRI) and H1-Magnetic resonance spectroscopic imaging (MRSI) were performed at University of Pittsburgh Medical Center Magnetic Resonance Research Center using a 7.0Tesla (7T) Siemens whole-body scanner (Siemens Medical Solutions, Erlangen, Germany).
Structural images for use in parcellation and aligning were obtained using an MP2RAGE sequence (<mark>1 mm isotropic resolution, TR/TE/flip angle 1/ flip angle 2: 26000 ms/2.47 ms/40/50 </mark>).

MRSI data was acquired using a J-refocused spectroscopic imaging sequence (Pan et al., 1996; Pan et al., 2010) (<mark>TE/TR = 17/1500ms</mark>) with RF based outer-volume suppression (Hetherington et al., 2010) and an 8x2 1H transceiver array using 8 independent RF channels (Avdievich, 2011).
High degree B0 shimming was used to improve field homogeneity (Pan et al., 2012).
<mark>One slice was acquired (10mm thick 24x24 encodes across a FOV of 216x216 mm <1cc effective resolution)</mark>.
The slice was axially positioned to include DLPFC (BA46/BA9).
In order to minimize individual variability in brain morphology and slice positioning, a program developed in-house was used during acquisition to map an oblique slice atlas into the subject’s native space in real-time.
This allowed for that image to be uploaded to the scanner and used for placement.

</mark>[INSERT PRE-PROCESSING DETAILS HERE? - @Will, sorry, I really have no idea what you do/if there’s anything to include here. You can just write some stuff and I can make them into sentences. Freesurfer segmentation? Idk.]</mark>


Individual voxels used in analysis were manually chosen in regions of interest (ROI) using a program developed in-house. Voxels were selected in order to optimize spectral quality upon visual inspection and maximize fraction of gray matter. The voxel was then confirmed to bein the desired ROI by warping the subject’s native space into MNI space and checking using the Talairach-Tournoux atlas as provided by AFNI’s whereami (Cox, 1996). Spectrum files were extracted using a program developed in-house. Metabolite concentrations were then quantified inreference to creatine (Cr) using LCModel (Provencher, 2001). Spectra were excluded if the Cramer-Rao Lower Bound (CRLB) for NAA, Cr, or Cho was > 10 (representing poor quality spectra) or if MM/Cr was > 3 (representing a large macromolecule contribution that could distortmetabolite quantification). Individual metabolites were excluded if their Cramer-Rao Lower Bounds (CRLBs) were > 20.
