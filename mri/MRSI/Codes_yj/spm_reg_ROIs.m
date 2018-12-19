function spm_reg_ROIs(ROI_dir, filename_table, filename_scout, filename_flair)
% SPM_REG_ROIs register freesurfer orig and rois to the scout (slice) space
% * ROI_dir contains scout.nii, orig.nii, and all "roi.nii" files
% * table, scount, and optional flair filenames are
%  - table: tab sep file containing roi names. see grouping_mask
%  - scout: the reference for the registration, in same space as CSI slice
%  - flair: ....
% originally spm_registration_ROI_ft_plusExtras
% depends on "SPMcoreg.mat" for mostly configure spmbatch var 'matlabbatch'
% OUTPUT:
%   files like rthalmus.nii and rparietal_wm.nii
% N.B. coregisration is a little stocastic. individual runs of this function
%      will produce slighly different nifitis


%% get filename string for rename (scout=ref)
% /path/to/scout.nii -> /path/to/scout_resize.nii
[data_dir, scout_nii, ext ] = fileparts(filename_scout);
scout_nii = [scout_nii ext];
pos = strfind(scout_nii,'.'); pos=pos(end); % grab the last . (.nii) problem for .nii.gz
scout_resized = fullfile(data_dir,[scout_nii(1:(pos-1)),'_resize.nii,1']);

%% read in roi list and prepare for spm (rois=other)
% e.i. repeat what we do in grouping_masks
t = readtable(filename_table,'ReadVariableNames',1);
t = [t rowfun(@name_mask,t(:,{'name','matter'}),'OutputVariable','nii')];
% restrict to just those with a name name
use_t = ~ cellfun(@isempty,t.name);
t = t(use_t,:);

% get a cell of nifiti files ready for spm (estwrite.other)
dir_vol1 = @(nii) [fullfile(ROI_dir, nii) ',1'];
roi_file_list = cellfun(dir_vol1,  t.nii,'UniformOutput',0);
% and while were are at it, get orig (source) how spm likes it 
orig = dir_vol1('orig.nii'); % now like roi/dir/orig.nii,1


%% Coregister MPRAGE to resized Scout (trilinear). 
% take all the rois with the mprage (freesurfer) into the scout (slice) space

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
    matlabbatch = get_matlabbatch();
    matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {scout_resized}';
    matlabbatch{1}.spm.spatial.coreg.estwrite.source = {strcat(filename_flair,',1')}';
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
%   matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [1 1 2];
    spm_jobman('run',matlabbatch);
end

close all;
