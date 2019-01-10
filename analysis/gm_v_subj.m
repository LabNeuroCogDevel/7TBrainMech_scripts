%% functions stored elsewhere
addpath('/Volumes/Zeus/DB_SQL') % get db_query.m
% SI1_to_nii for reading in sheet
addpath('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/Codes_yj/')

d = readtable('all_measures_20190109.csv');

gm_prct=0:.05:1;
subj_cnt=zeros(size(gm_prct)); % make subj_cnt as many zeros as in gm_prct
gm_vox_cnt=zeros(size(gm_prct));

% for each subject
%% load gm for each subject
for row_i=1:height(d)
    subj=d{row_i,'lunaid'};
    csi_roi_dir=d{row_i,'csidir'}; csi_roi_dir=csi_roi_dir{1};
    try
        gm=read_in_2d_csi_mat(strtrim(ls(fullfile(csi_roi_dir,'*_FractionGM_FlipLR'))));
        tissue_file = strtrim(ls(fullfile(csi_roi_dir,'*_MaxTissueProb_FlipLR')));
        tissue=read_in_2d_csi_mat(tissue_file);
    catch
        gm=-Inf(24,24);
        tissue=-Inf(24,24);
        fprintf('victor code bad')
    end
    
    %% increase count if subject has gm at each threshold
    % for each index (p_i) in p
    mask = tissue > 0.8;
    for prct_i = 1:length(gm_prct)
        if nnz(gm >= gm_prct(prct_i)) >= 1
            subj_cnt(prct_i) = subj_cnt(prct_i)+1;
        end 
        gm_vox_cnt(prct_i)= gm_vox_cnt(prct_i)+nnz(gm >= gm_prct(prct_i));
        
        
    end
    
    

end

plot(gm_prct, subj_cnt)
figure;
plot(gm_prct, gm_vox_cnt)

gm_voxels_subj=[prct_i, gm_prct, gm_vox_cnt]


