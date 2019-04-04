%% functions stored elsewhere
addpath('/Volumes/Zeus/DB_SQL') % get db_query.m
% SI1_to_nii for reading in sheet
addpath('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/Codes_yj/')

d = readtable('all_measures_20190109.csv');

gm = -Inf(height(d),24,24);
tis= gm;
tha = gm;
% for each subject
%% load gm for each subject
for row_i=1:height(d)
    subj=d{row_i,'lunaid'};
    csi_roi_dir=d{row_i,'csidir'}; csi_roi_dir=csi_roi_dir{1};
    try
        gm(row_i,:,:)=read_in_2d_csi_mat(strtrim(ls(fullfile(csi_roi_dir,'*_FractionGM_FlipLR'))));
        tis(row_i,:,:)=read_in_2d_csi_mat(strtrim(ls(fullfile(csi_roi_dir,'*_MaxTissueProb_FlipLR'))));
        tha(row_i,:,:)=read_in_2d_csi_mat(strtrim(ls(fullfile(csi_roi_dir,'*_csivoxel_FlipLR.THA'))));
    catch
        fprintf('victor not finished on %d (but have %s)\n',subj, d.sheet{row_i});
    end
end

%% get an idea of what things look like    
a = squeeze(sum(gm > .2 & tis > .1))
imagesc(a)

%% generate gm thresholds
ratio_vals=0:.05:1;
n_rats=length(ratio_vals);
n_subj=height(d);
nz_cnt_thres=zeros(n_rats,n_subj);
for r_i=1:n_rats
    for s_i=1:n_subj
        nz_cnt_thres(r_i, s_i) = nnz( gm(s_i,:,:) > ratio_vals(r_i) & tha(s_i,:,:) > .1);
    end
end
imagesc(nz_cnt_thres);