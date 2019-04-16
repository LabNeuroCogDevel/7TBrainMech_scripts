function [subj] = subject_files(mrid)
%% what files do we care about?
%subj.data_dir=sprintf('/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/atlas_roi',subj_id);
project_dir = '/Volumes/Hera/Projects/Collab/7TFF/';
subj_id = mrid;
subj.roi_mprage=sprintf('%s/subjs/%s/slice_PFC/roi_mprage.nii.gz', project_dir,subj_id);
subj.slice_txt=sprintf('%s/subjs/%s/slice_PFC/MRSI/scout_slice_num.txt',project_dir,subj_id);
subj.filename_scout=sprintf('%s/subjs/%s/slice_PFC/MRSI/scout.nii',project_dir,subj_id);
subj.subj_mprage=sprintf('/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/ppt1/mprage.nii.gz',subj_id);
subj.csi = NaN; % get later
% get slice number for files dependent on it
slice_num = NaN;
if exist(subj.slice_txt,'file'), slice_num = load(subj.slice_txt); end
% get frac gm
subj.fracgm_file = sprintf('%s/subjs/%s/slice_PFC/MRSI/2d_csi_ROI/%d_FractionGM_FlipLR',project_dir, subj_id, slice_num);
subj.fractis_file = sprintf('%s/subjs/%s/slice_PFC/MRSI/2d_csi_ROI/%d_MaxTissueProb_FlipLR', project_dir, subj_id, slice_num);

% csi could be in two other places
if ~exist(subj.csi,'file') 
    csidir = dir(sprintf('/Volumes/Hera/Raw/MRprojects/Other/FF/MRSI/*/*/%s/CSI*PFC/spreadsheet.csv', mrid)); 
    if ~isempty(csidir)
        subj.csi = fullfile(csidir(1).folder, csidir(1).name);
    end
end


%% do we have all files?
haveall=1;
for f=fieldnames(subj)'
    this_file = subj.(f{1});
    if ~exist(this_file,'file')
        warning('%s/%s: missing %s file %s', subj_id, mrid, f{1}, this_file)
        haveall=0;
    end
end
subj.have_all_files = haveall;



%% populate not file fields
% ids
subj.mrid = mrid;
subj.subj_id = subj_id;
% add slice to struct
subj.scout_slice = slice_num;


end

