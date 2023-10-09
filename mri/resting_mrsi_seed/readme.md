20230508
  `mkTS_roi.bash` and `hurst.m` using non-warped rest preprocessing with mprage->func MRSI PFC13 rois. 

20221014
  see /Volumes/Hera/Projects/Maria/7Trest_mrsi for rest of pipeline
20221012
 - use ../MRSI_roi/gaba_glu_r/out/gaba_glu.csv to identify good visits per roi
 - generate converage map of good visits 
 - find coordinate with most coverage in map
 - center a 7mm sphere there and remove Pr(GM)<.5 (MNI graymatter prob atlas)
 - get timeseries average for each roi for each rest visit and 3dTcorr1D that with rest (cor-r)
