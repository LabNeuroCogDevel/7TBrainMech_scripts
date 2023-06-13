% read in roi time series (nvol x nroi) per subject (see mkTS_roi.bash)
% generate per visit Hurst Exponent (EI balance proxy measure)
% https://github.com/elifesciences-publications/ei_hurst/blob/master/code/C_1a_parcEst.m
% 20230508WF - init
% 20230613WF - moved meat into hurt_parfor.m


%Non-fractal-master/m/bfn_mfin_ml.m args
% copied from ei_hurst elife paper
nroi = 1000;
roi_ts_1d = dir('txt/*_schaefer2018N17_1000.1D')';

ld8s = arrayfun(@(x) regexprep(x.name, '|_schaef.*',''), roi_ts_1d,'Uni',0);
ld8_table = cell2table(ld8s','VariableNames',{'ld8'});

% initialize and run in parallel
H_all = hurst1D_parfor(roi_ts_1d, nroi)

%%% combine as table for easy write to csv

%% relabel using acutual names
roi_labels = readtable('/opt/ni_tools/atlas/schaefer2018/Schaefer2018_LocalGlobal/Parcellations/project_to_individual/Schaefer2018_1000Parcels_17Networks_order_LUT.txt');
labels =  regexprep(roi_labels.Var2',' ','');
assert(length(labels) == nroi)
%out_table.Properties.VariableNames = ...
%   regexprep(out_table.Properties.VariableNames,'Var','ROI');
H_table = array2table(H_all);
H_table.Properties.VariableNames = labels;


out_table = [ld8_table, H_table];
writetable(out_table, 'stats/schaefer2018N17_H.csv')
