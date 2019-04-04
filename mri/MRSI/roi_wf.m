%% code paths
addpath('/home/ni_tools/matlab_toolboxes');
addpath('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/Codes_yj')

%% settings
csi_json='/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/csi_settings.json';
B0ScoutThk_resize = 1; % resized B0 scout thickness [mm]
CurrentScoutSliceNum = 17;


%% subject specific paths
subj_date = '11686_20180917';

% TODO: use sprintf to make these paths dependent on subj_date
% e.g. 
%  subj_root = fullfile('/Volumes/Hera/Projects/7TBrainMech/subjs',subj_date,'slice_PFC');
roi_mprage_file = '/Volumes/Hera/Projects/7TBrainMech/subjs/11686_20180917/slice_PFC/roi_mprage.nii.gz';
subj_mprage = '/Volumes/Hera/Projects/7TBrainMech/subjs/11686_20180917/slice_PFC/ppt1/mprage.nii.gz';
filename_scout='/Volumes/Hera/Projects/7TBrainMech/subjs/11686_20180917/slice_PFC/MRSI_tes4_2018-12-13/scout.nii';
s17_template = '/Volumes/Hera/Projects/7TBrainMech/subjs/11686_20180917/slice_PFC/MRSI_tes4_2018-12-13/s17_9x9.nii.gz';
% TODO: check e.g. exists(roi_mprage_file, 'file') and error('no file') if
% fails

% TODO: make data dir within subj directory
data_dir='/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/roi_dir';
mkdir(data_dir)

%% %%%  File setup %%% %%
% we already have 
%   - our atlas (MNI space) warped to subjects mprage space
%   - a B0 scout image
%   - a t1/mprage
% we need
%   - an unzipped copy of the scout (resized to mprage and 1mm x 1mm x 1mm)
%   - an individual file for each roi (to register to scout)
%   - an unzipped copy of the subjects mprage (to register to scout)

%% read in ROI atlas (defined by Finn), already registred to subj mprage
img_nii = load_untouch_nii(roi_mprage_file);
roi_4d = img_nii.img;
copyfile(roi_mprage_file, data_dir)


%% find nroi
nroi=max(img_nii.img(:)); % 11

%% make a file for each roi
roi_filenames = {};

for roi_num=1:nroi
    roi_file = sprintf('roi_%02d.nii', roi_num);
    roi_filenames= [roi_filenames roi_file]; % make list of all filenames
    [roi_mask,~] = ROI_from_Parcel(roi_4d, [roi_num]);
    img_nii.img = double(roi_mask);
    save_untouch_nii(img_nii, fullfile(data_dir,roi_file));
end

%% resize scout
% copy scout to data_dir if its not already there
if ~exist(fullfile(data_dir,'scout.nii'), 'file')
    copyfile(filename_scout,data_dir)
end
img_resize_ft(data_dir,'scout.nii');   % makes scout_resize.nii
scout = fullfile(data_dir,'scout.nii');

%% unzip mprage
if ~exist(fullfile(data_dir,'mprage.nii'), 'file')
   copyfile(subj_mprage, data_dir);
   gunzip(fullfile(data_dir,'mprage.nii.gz')); % gnu unzip of mprage.nii.gz -> mprage.nii
end

%% %%% Calculations %%% %%
%
% now we have all the files
% we need to 
%  - register mprage and rois to B0 scout 
%  - id best roi for each voxel (max)
%  - get probability of roi being in the slice 

%% register roi and mprage to scout
% must be nii not nii.gz -- spm will fail otherwise
spm_reg_ROIs(data_dir, roi_filenames', scout, [], 'mprage.nii') 
% creates rmprage.nii

%% read in registered roi and mparge

% read in registred-to-slice  mprage
mprage_file = fullfile(data_dir,'rmprage.nii');
img_nii = load_untouch_nii(mprage_file);   % input
mprage = img_nii.img;

% pulling out bits of 
% input roi are registered -- names prefixed wiht 'r'
reg_roi_names = cellfun(@(x) ['r' x], roi_filenames, 'UniformOutput', 0);
prob_4d_orig = idv_nii_to4d(data_dir, reg_roi_names); % 216   216    99    11
nroi = size(prob_4d_orig,4);

%% match FOV
prob_4d = match_B0_CSI_1(prob_4d_orig, csi_json);
mprage  = match_B0_CSI_1(mprage,  csi_json);

%% get index of roi at each voxel (if 2 and 4 share voxel, 4 wins b/c its higher)
% [a,b] = max([100 200 150; 300 100 400; NaN 0 0],[],2); % a=[200 400] b=[2 3 1]
[~, parc_comb] = max(prob_4d, [], 4);
% if we had a voxel that was 0 in every roi, it'd be assigned to the first
% need to assign no-roi-voxels to 0
mask = sum(prob_4d,4) ~= 0;
parc_comb = parc_comb .* mask;

    
%% Locate CSI slice, select just that bit
% Sampling PSF and Hanning filter (apodization)
% Apply slice profile
% Calculate probability


% 13 1mm slices in b0 slice 17 representing csi plane
parc_comb_ct = extract_csi_slice(parc_comb, 17, csi_json, B0ScoutThk_resize);
mask_ct      = extract_csi_slice(mask,      17, csi_json, B0ScoutThk_resize);
mprage_ct    = extract_csi_slice(mprage,    17, csi_json, B0ScoutThk_resize);



% get percent voxel in roi
parc_comb_prob = prob_apodize_1(parc_comb_ct, csi_json, nroi);

%% %%% Reorgainze the matricies %%% %%
% all the calculations and resizing is finished
% we have a 24x24 matrix for each roi
% now we need to find a way to show it off
%

%% flip all 
parc_comb_prob_flip = nan(size(parc_comb_prob));
for ri=1:nroi 
    parc_comb_prob_flip(:,:,ri) = fliplr(parc_comb_prob(:,:,ri));
end

%% write to nifti and plot
spnx = ceil(sqrt(nroi+3)); spny = round(sqrt(nroi+3));
for ri=1:nroi
    % plot
    subplot(spnx,spny,ri);
    colormap(gca,'jet');
    imagesc(parc_comb_prob_flip(:,:,ri));
    colorbar;
    
    % write nifti
    roi_name=sprintf('roi_%d.nii',ri);
    csi2d_to_nii(...
      parc_comb_prob_flip(:,:,ri),...
      fullfile(data_dir,roi_name), ...
      s17_template);
end

% and look at rois
subplot(spnx,spny,nroi+1)
colormap(gca,[[0,0,0]; flipud(jet(nroi))]);
image(max(mprage_ct,[],3))
colorbar;


%% look at in matlab
% blow up max probs as if it's same size as mprage (24 -> 216)
% center of 13 mprage slices +fliplfr
parc_max = max(parc_comb_prob_flip,[],3);
center_slice = fliplr(mprage_ct(:,:,round(size(mprage_ct,3)/2)));
% view
f1 = imagesc_overlay(center_slice, parc_max, 'Range', [0 .04]);

%% whats wrong with rois
all_rois = max(max(prob_4d_orig,[],4),[],3); % collapse all rois and z axis
roi_jet = [[0,0,0]; flipud(jet(nroi))]; % color scheme for rois

imagesc_overlay(center_slice, fliplr(all_rois), 'Color', roi_jet);

% for viewing -- pick the center of the 13 mprage slices
parc_collapsed = max(parc_comb_ct,[],3);
imagesc_overlay(center_slice, parc_collapsed,'Color', roi_jet);





