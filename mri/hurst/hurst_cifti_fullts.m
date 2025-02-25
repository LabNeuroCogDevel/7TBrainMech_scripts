%% setup
addpath('/opt/ni_tools/matlab_toolboxes/WashUCifti'); % cifti_read
addpath(genpath('/opt/ni_tools/matlab_toolboxes/wmtsa/')); 
addpath(genpath('/opt/ni_tools/matlab_toolboxes/nonfractal/')); % needed for wmtsa
% hurst lower and upper bounds
lb = [-0.5 0];
ub = [1.5 10];

% read single file
%ciftis = dir('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/xcpd_fd-0_bp-no/ses-1/sub-10129/func/sub-10129_task-rest_run-01_space-fsLR_seg-Glasser_den-91k_stat-mean_timeseries.ptseries.nii');
full_ts = dir('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/xcpd_fd-0_bp-no/ses-1/sub-10129/func/sub-10129_task-rest_run-01_space-fsLR_den-91k_desc-denoised_bold.dtseries.nii');

nroi = 91282; % hard coded -- was 360
nvisits = length(full_ts);

% initialize and run in parallel
H_all=zeros(nvisits, nroi); % output 

%parpool() % clusters=10 % TODO(20250225) lookup usage
%parfor di=1:length(nvol)
  di = 1;
  % read in data
  this_file = fullfile(full_ts(di).folder, full_ts(di).name);
  ts = cifti_read(this_file);
  
  % roi x timepoints
  % !!NB!! opposite order of hurst input
  % size(gordon_t.cdata) == [360   220];

  hurst_in = double(ts.cdata'); % must be double
  [H, nfcor, fcor] = bfn_mfin_ml(hurst_in, 'filter', 'Haar', 'lb', lb, 'ub', ub);
  % size(H) = 1x13 (nROI)
  % size(nfcor) == size(fcor) == nRoi x nROI == 13x13
  H_all(di,:) = H;
%end
