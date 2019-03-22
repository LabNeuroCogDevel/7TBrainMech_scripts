function spm_reg_ROIs(ROI_dir, filename_table, filename_scout, filename_flair, t1, redo)
% SPM_REG_ROIs register freesurfer orig and rois to the scout (slice) space
% * ROI_dir contains scout.nii, orig.nii, and all "roi.nii" files
% * table, scount, and optional flair filenames are
%  - table: path to tab sep file containing roi names. see grouping_mask
%           OR cell of filenames (no path)
%  - scout: the reference for the registration, in same space as CSI slice
%  - flair: ....
%  - t1: default is freesurfer's 'orig.nii'
% originally spm_registration_ROI_ft_plusExtras
% depends on "SPMcoreg.mat" for mostly configure spmbatch var 'matlabbatch'
% OUTPUT:
%   files like rthalmus.nii and rparietal_wm.nii
% N.B. coregisration is a little stocastic. individual runs of this function
%      will produce slighly different nifitis

if nargin < 5
   t1 = 'orig.nii';
end

if nargin < 6
    redo = 0;
end

%% get filename string for rename (scout=ref)
% /path/to/scout.nii -> /path/to/scout_resize.nii
[data_dir, scout_nii, ext ] = fileparts(filename_scout);
scout_nii = [scout_nii ext];
pos = strfind(scout_nii,'.'); pos=pos(end); % grab the last . (.nii) problem for .nii.gz
scout_resized = fullfile(data_dir,[scout_nii(1:(pos-1)),'_resize.nii,1']);
% check that resized exists
if ~ exist(scout_resized(1:end-2),'file'), error('Do not have %s, rerun img_resize_ft',scout_resized), end

%% read in roi list and prepare for spm (rois=other)
% e.i. repeat what we do in grouping_masks
if ischar(filename_table) 
   t = readtable(filename_table,'ReadVariableNames',1);
   t = [t rowfun(@name_mask,t(:,{'name','matter'}),'OutputVariable','nii')];
   % restrict to just those with a name name
   use_t = ~ cellfun(@isempty,t.name);
   t = t(use_t,:);
   nii_list = t.nii;
elseif iscell(filename_table)
   nii_list = filename_table;
else 
   error('filename_table argument should be a path to roi csv, or cell of filenames')
end

% get a cell of nifiti files ready for spm (estwrite.other)
dir_vol1 = @(nii) [fullfile(ROI_dir, nii) ',1'];
roi_file_list = cellfun(dir_vol1,  nii_list, 'UniformOutput',0);
% and while were are at it, get orig (source) how spm likes it 
orig = dir_vol1(t1); % now like roi/dir/orig.nii,1

% check file exist
if ~ exist(orig(1:end-2),'file'), error('Do not have t1 %s',orig), end

%% dont run if we have everything we want
alreay_done=1;
for f = [nii_list; t1]'
    outfile = fullfile(ROI_dir,['r' f{1}]);
    if ~exist(outfile,'file')
        alreay_done=0;
        break
    %else
    %    warning('already ran spm registration on %s, have %s', f{1}, outfile);
    end
end
if alreay_done && ~redo
    fprintf('already ran spm registration on all %s files, skipping\n', ROI_dir)
    return
end

%% Coregister MPRAGE to resized Scout (trilinear). 
% take all the rois with the mprage (freesurfer) into the scout (slice) space
disp('spm: trilinear warp')
% load premade matlabbatch{1}.spm.spatial.coreg.estwrite
matlabbatch = get_matlabbatch();
matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {scout_resized}';
matlabbatch{1}.spm.spatial.coreg.estwrite.source = {orig}';
% use same warp to get mask rois in slice space
matlabbatch{1}.spm.spatial.coreg.estwrite.other = roi_file_list;
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 0;
% matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [1 1 1];

spm fmri

spm_jobman('run',matlabbatch);
spm_extract_affine_matrix(fullfile(ROI_dir,'mprage_to_scout_trilinear.txt'));
clear matlabbatch;


%% Coregister MPRAGE to resized Scout (4th degree)
% TODO: why? do we use this?
disp('spm: trilinear wapr, apply to all')
matlabbatch = get_matlabbatch();
matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {scout_resized}';
matlabbatch{1}.spm.spatial.coreg.estwrite.source = {orig}';
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
% matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [1 1 1];

spm_jobman('run',matlabbatch);
spm_extract_affine_matrix(fullfile(ROI_dir,'mprage_to_scout_4thdeg.txt'));
clear matlabbatch;


%% Coregister FLAIR to resized Scout
if ~isempty(filename_flair) && exists(filename_flair,'file')

    disp('spm: warp flair')
    matlabbatch = get_matlabbatch();
    matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {scout_resized}';
    matlabbatch{1}.spm.spatial.coreg.estwrite.source = {strcat(filename_flair,',1')}';
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
%   matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [1 1 2];
    spm_jobman('run',matlabbatch);
end

close all;
