% 20240226 - AO's ROIs
% /Volumes/Hera/Amar/atlas/hurst_rois/nacc_amyg_hpc.nii.gz
% copy of hurst_schaefer.m and hurst.m
function out_table = hurst_ROI_naccAmygHpc(saveas,nroi, varargin)

% defaults. hopefully match Makefile
if nargin < 1
   saveas = 'roi-naccamyghpc_H-brnswdkm.csv';
end
if nargin < 2
   glob_1d=varargin{:};
else
   glob_1d='txt/1*_2*_nacc_amyg_hpc.1D';
end

roi_ts_1d = dir(glob_1d)';
H_all = hurst1D_parfor(roi_ts_1d, nroi)

roi_labels = {'LNAcc','RNAcc','Lamyg','Ramyg','Lhpc','Rhpc'};

H_table = array2table(H_all);
H_table.Properties.VariableNames = labels;


ld8s = arrayfun(@(x) regexprep(x.folder, '.*/',''), roi_ts_1d,'Uni',0);
ld8_table = cell2table(ld8s','VariableNames',{'ld8'});
out_table = [ld8_table, H_table];


writetable(out_table, saveas)
