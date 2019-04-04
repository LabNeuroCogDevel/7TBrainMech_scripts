function[row_of_max, col_of_max]= csi_roi_vox(subj_id)
%% toolboxes and functions
addpath('/home/ni_tools/matlab_toolboxes');
addpath('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/Codes_yj')
addpath('/opt/ni_tools/matlab_toolboxes/spm12/');

%% csi settings
csi_json='/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/csi_settings.json';

%% subject info/files
% can take in a struct, or lookup the struct
if(isstruct(subj_id)) 
    subj=subj_id;
    subj_id=subj.subj_id;
else
    subj = subject_files(subj_id);
end

roi_mprage = subj.roi_mprage;
filename_scout = subj.filename_scout;
subj_mprage= subj.subj_mprage;
center_slice = subj.scout_slice;
data_dir=sprintf('/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/atlas_roi',subj_id);

% previously h
%roi_mprage=sprintf('/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/roi_mprage.nii.gz',subj_id);
%filename_scout=sprintf('/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/MRSI/scout.nii',subj_id);
%subj_mprage=sprintf('/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/ppt1/mprage.nii.gz',subj_id);

%% checks
if ~exist(filename_scout,'file'),error('file DNE %s', filename_scout),end
if ~exist(roi_mprage,'file'),error('file DNE %s', roi_mprage),end
if ~exist(subj_mprage,'file'),error('file DNE %s', subj_mprage),end
%% make data dir
if ~exist(data_dir,'dir'), mkdir(data_dir); end
%% read in Finn's ROIs
gunzip(roi_mprage, data_dir) 
roi_nii = load_untouch_nii(fullfile(data_dir, 'roi_mprage.nii'));
img_nii = roi_nii;

%% find nroi (11 ROIs as defined by Finn)
nroi=max(img_nii.img(:)); % 11 ROIs

%% make a file for each ROI
roi_filenames = {};
for roi_num=1:nroi
    roi_file = sprintf('roi_%02d.nii', roi_num);
    roi_filenames = [roi_filenames roi_file]; %make a list of files
    [roi_mask, ~] = ROI_from_Parcel(roi_nii.img, [roi_num]);
    img_nii.img = double(roi_mask); 
    save_untouch_nii(img_nii, fullfile(data_dir,roi_file));
end 

%% resizing scout

scout_file= fullfile(data_dir,'scout.nii');

%test for file
if ~exist(scout_file, 'file')
    copyfile(filename_scout,data_dir)
end
img_resize_ft(data_dir,'scout.nii');

%% register scout
% get MPRAGE, get rid of nii.gz
gunzip(subj_mprage, data_dir) 

%run SPM register
spm_reg_ROIs(data_dir, roi_filenames', scout_file, '', 'mprage.nii') 

%% Resize B0 scout
B0ScoutThk_resize = 1; % resized B0 scout thickness [mm]

%% Read in nifti (slice registered ROIs)
mprage_file = fullfile(data_dir,'rmprage.nii');
img_nii = load_untouch_nii(mprage_file);   % input
mprage = img_nii.img;
[h,w,s] = size(mprage);

if h ~= w
   error('mprage is not symetic (%d x %d), will not be able to rotate! (%s)',...
       h, w, mprage_file);
end

%% read in rois, combine separate roi files into one 4d matrix
reg_roi_names = cellfun(@(x) ['r' x], roi_filenames, 'UniformOutput', 0);
prob_4d = idv_nii_to4d(data_dir,reg_roi_names);
nroi = size(prob_4d,4);
%% match grids
[prob_4d, mprage, ~] = ...
    match_B0_CSI(prob_4d, mprage, [], csi_json);

%% combine segmentation
[~, parc_comb] = max(prob_4d, [], 4);
% mask = sum(prob_4d,4) >= 0.6;
mask = sum(prob_4d,4) ~= 0;
parc_comb = parc_comb .* mask;

% save as nii format
img_nii.img = parc_comb;
save_untouch_nii(img_nii, fullfile(data_dir, 'parc_newbin.nii'));

%% locate CSI slice section
disp('apodize')
% Sampling PSF and Hanning filter (apodization)
    % Apply slice profile
    % Calculate probability
    [parc_comb_prob, ...
     mprage_ct, flair_ct, mask_ct, parc_comb_ct] = ...
        prob_apodize(center_slice, csi_json, ...
        B0ScoutThk_resize, parc_comb, mask, mprage, [], size(prob_4d,4));
%% Flip R-L
disp('L-R Flip on all outputs')
  for rg = 1:size(prob_4d,4)
        parc_comb_prob(:,:,rg) = fliplr(parc_comb_prob(:,:,rg));        
  end
    for yj = 1:size(parc_comb_ct,3)
        parc_comb_ct(:,:,yj) = fliplr(parc_comb_ct(:,:,yj));
        mprage_ct(:,:,yj) = fliplr(mprage_ct(:,:,yj));
        mask_ct(:,:,yj) = fliplr(mask_ct(:,:,yj));
        if ~isempty(flair_ct)
            flair_ct(:,:,yj) = fliplr(flair_ct(:,:,yj));
        end
    end
%% make pretty picture of brain 
% need to change this to be subject 10644_20180216
% tempimage = '/Volumes/Hera/Projects/7TBrainMech/subjs/11686_20180917/slice_PFC//MRSI_tes4_2018-12-13/s17_9x9.nii.gz'
% csi2d_to_nii(parc_comb_prob(:,:,1),['roi3.nii'],tempimage)
%  
% parc_max = max(parc_comb_prob,[],3);
% center_slice = fliplr(mprage_ct(:,:,round(size(mprage_ct,3)/2)));
% parc_max_180 = rot90(parc_max, 2);
% center_slice_180 = rot90(center_slice, 2);
% f1 = imagesc_overlay(center_slice_180, parc_max_180, 'Range', [0 .4]);

%% read in csv file, get max index and value of ROI, find that value in spreadsheet
row_of_max=zeros(nroi,1);
col_of_max=zeros(nroi,1);

for roi_num=1:nroi
    roi_comb_prob=parc_comb_prob(:,:,roi_num);
    [parc_max,parc_idx] = max(roi_comb_prob(:));
    [row_of_max(roi_num),col_of_max(roi_num)] = ind2sub(size(parc_comb_prob), parc_idx);
end

%voxel = d.Row==row_of_max&d.Col==col_of_max;
%d.GABA_Cre(voxel)

end

