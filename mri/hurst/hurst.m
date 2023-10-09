% read in roi time series (nvol x nroi) per subject (see mkTS_roi.bash)
% generate per visit Hurst Exponent (EI balance proxy measure)
% https://github.com/elifesciences-publications/ei_hurst/blob/master/code/C_1a_parcEst.m
% 20230508WF - init
% 20230613WF - moved meat into hurt_parfor.m


%Non-fractal-master/m/bfn_mfin_ml.m args
% copied from ei_hurst elife paper
nroi = 13;
roi_ts_1d = dir('/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/*/mrsipfc13_nzmean_ts.1D')';
H_all = hurst1D_parfor(roi_ts_1d, nroi)
out_table = labelrois_ld8(H_all,roi_ts_1d,nroi)
writetable(out_table, 'stats/MRSI_pfc13_H.csv')

roi_ts_1d = dir('/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/*/mrsipfc13_nzmean_nsdkm_ts.1D')';
H_all = hurst1D_parfor(roi_ts_1d, nroi)
out_table = labelrois_ld8(H_all,roi_ts_1d,nroi)
writetable(out_table, 'stats/MRSI_pfc13_nsdkm_H.csv')
