% read in roi time series (nvol x nroi) per subject (see mkTS_roi.bash)
% generate per visit Hurst Exponent (EI balance proxy measure)
% https://github.com/elifesciences-publications/ei_hurst/blob/master/code/C_1a_parcEst.m
% 20230508WF - init


addpath(genpath('/opt/ni_tools/matlab_toolboxes/wmtsa/'))
addpath(genpath('/opt/ni_tools/matlab_toolboxes/nonfractal/'))


%Non-fractal-master/m/bfn_mfin_ml.m args
% copied from ei_hurst elife paper
lb = [-0.5 0];
ub = [1.5 10];
nroi = 13;
roi_ts_1d = dir('/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/*/mrsipfc13_nzmean_ts.1D')';

% initialize and run in parallel
H_all=zeros(length(roi_ts_1d), nroi);
parfor di=1:length(roi_ts_1d)
   d = roi_ts_1d(di)
   % nvol x nroi (220x13)
   ts = load(fullfile(d.folder,d.name));
   [H, nfcor, fcor] = bfn_mfin_ml(ts, 'filter', 'Haar', 'lb', lb, 'ub', ub);
   % size(H) = 1x13 (nROI)
   % size(nfcor) == size(fcor) == nRoi x nROI == 13x13
   H_all(di,:) = H;
end

% combine as table for easy write to csv
ld8s = arrayfun(@(x) regexprep(x.folder, '.*/',''), roi_ts_1d,'Uni',0);
out_table = [cell2table(ld8s','VariableNames',{'ld8'}), ...
             array2table(H_all)];
out_table.Properties.VariableNames = ...
   regexprep(out_table.Properties.VariableNames,'Var','ROI');

writetable(out_table, 'stats/MRSI_pfc13_H.csv')
