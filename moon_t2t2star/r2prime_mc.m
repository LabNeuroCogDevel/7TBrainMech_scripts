function output = r2prime_mc(id) 
% output is struct with file names and mats
% T2 & T2* mapping
% @wf  - 20190327   - use 'ts' input instead of one file per echo
% @wf  - 20190325   - resume custom
% @wf  - 20181206   - customize for lncd/rhea from @chm code
%
%
%{
1. T2prep_gre_t2t2star sequence acquires mutli-echo (N_T2star) GRE data (for T2* mapping) 
per one spin-echo time, and repeated acquisition with different spin-echo time (N_T2) 
(for T2 mapping). So, the data consists in N_T2star*N_T2 files.

2. The mapping script uses NIfTI file format - Use "dcm2niix", Chris Rorden's dcm2niiX version 
v1.0.20170821 GCC5.4.0 (64-bit Linux)

3. Data foler consists of "StudyName(ex, 20190930)", and the subfolders of "Anylze", "DICOM", 
and "Processing". "Anylze" - nifti files; "Processing" - matablab program
and result files
%}

% Nifti library files are required to read and save
addpath(genpath('/opt/ni_tools/matlab_toolboxes/NIfTI/'));

% smoothed by 3x3x3
% N_T2star(5) files are for T2star mapping data, and N_T2(3) groups of
% T2 mapping files

%% collect data, find or make mc and warp_mat
all_t2t2s = create_t2t2star_mc(id);

%% test expected output
basedir = all_t2t2s.basedir; % where R2Prime directory is for this subject
pfolder = fullfile(basedir,'mc_mni');

output.t2map = fullfile(pfolder,'TTmap.nii');
output.m0    = fullfile(pfolder,'M0map.nii');
output.t2smap= fullfile(pfolder,'TTStarmap.nii');
output.m0s   = fullfile(pfolder,'M0Starmap.nii');
output.r2prime=fullfile(pfolder,'r2prime.nii');
output.r2prime_mni=fullfile(pfolder,'r2prime_mni.nii.gz');

%% do we already have everything?
files_exist = cellfun(@(x) exist(output.(x), 'file'),fieldnames(output));
if all(files_exist), return, end


%% combine, motion correct, and resample
ts = load_untouch_nii(all_t2t2s.mc);

%% Parameters
% 12 timepoints, 3 sets of 4
% first protocol is T2*
% first echo of each is T2
idxT2  = [1 5 9]; % First indices in filelist for T2
idxT2s = [1 2 3 4] + 0; % First indices in filelist for T2star

TET2  = [40 60 100]*1e-3; %Spin echo time i sec
TET2s = [2.5 5.0 7.5 10.0]*1e-3; %GRE echo time in sec

T2data  = double(ts.img(:,:,:,idxT2));
T2sdata = double(ts.img(:,:,:,idxT2s));


%% how to save the data
image = ts;
image.hdr.dime.dim(5) = 1;


%% Processing
T0 = clock;

% Background threshold
threshT2  = 0.5*mean(T2data(:));
threshT2s = 0.5*mean(T2sdata(:));

% create directory where these will be saved
if ~exist(pfolder,'dir'), mkdir(pfolder); end

% T2 mapping (actually R2?)
if ~exist(output.t2map,'file')
   [TT,AA] = t2fitLin(single(T2data),TET2',threshT2); 
   image.img = TT*1e+3; save_untouch_nii(image,output.t2map);
   image.img = AA; save_untouch_nii(image,output.m0);
else
   a = load_untouch_nii(output.t2map);
   TT = a.img ./ 1e+3;
   AA = NaN;
end

% T2star mapping (actually R2star?)
if ~exist(output.t2smap,'file')
   [TTs,AAs] = t2fitLin(single(T2sdata),TET2s',threshT2s); 
   image.img = TTs*1e+3; save_untouch_nii(image,output.t2smap);
   image.img = AAs; save_untouch_nii(image,output.m0s);
else
   a = load_untouch_nii(output.t2smap);
   TTs = a.img ./ 1e+3;
   AAs = NaN;
end

% R2'
r2p = TT - TTs;
image.img = r2p.*1e+3;
save_untouch_nii(image,output.r2prime);

%% warp to mni using fsl's applywarp
mprage_warp = fullfile(basedir, '../preproc/t1/mprage_warpcoef.nii.gz');
mni_ref = fullfile(basedir,'../preproc/t1/template_brain.nii');
% check mprage files exist -- should have existed for intial flirt  to work
if ~exist(mprage_warp, 'file') || ~exist(mni_ref,'file')
   error(['missing warpfile (%s) and/or template (%s)!' ...
         'consider "pp  7TBrainMech_rest MHRest_nost_ica %s"'], ...
         mprage_warp, mni_ref, id)
end

warp_cmd = sprintf(['applywarp -i %s' ...
      ' -r %s' ...
      ' --premat=%s ' ...
      ' -w %s '...
      ' -o %s --interp=spline --rel'],...
      output.r2prime, mni_ref, all_t2t2s.warp_mat, mprage_warp, output.r2prime_mni);
run_ni(warp_cmd);
% compare to 
% applywarp -i mc_bet -r ../../preproc/t1/template_brain.nii --premat=t2_mprage.mat -w ../../preproc/t1/mprage_warpcoef.nii.gz -o mc_bet_mni.nii.gz --interp=spline --rel

%% return output mats for fun
output.mats.r2p = r2p;
output.mats.TT  = TT;
output.mats.TTs = TTs;
output.mats.AA  = AA;
output.mats.AAs = AAs;

%% time
T1 = clock;
eT1T0 = etime(T1,T0);
fprintf('Total duration for %s %.02f\n', id, eT1T0);

end
