%% functions stored elsewhere
addpath('/Volumes/Zeus/DB_SQL') % get db_query.m
% SI1_to_nii for reading in sheet
addpath('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/Codes_yj/')

d = readtable('all_measures_20190109.csv');
gm_prct=0:.05:1;
nsubj = height(d); 
nprct=  length(gm_prct);

subj_cnt=zeros(size(gm_prct)); % make subj_cnt as many zeros as in gm_prct

% 2d matrix that will fit all subjects (nsubj) for all thresholds (nprct)
gm_vox_cnt=zeros(nprct,nsubj);

% for each subject
%% load gm for each subject
for subj_i=1:height(d)
    subj=d{subj_i,'lunaid'};
    csi_roi_dir=d{subj_i,'csidir'}; csi_roi_dir=csi_roi_dir{1};
    try
        gm=read_in_2d_csi_mat(strtrim(ls(fullfile(csi_roi_dir,'*_csivoxel_FlipLR.FGM'))));
        tissue_file = strtrim(ls(fullfile(csi_roi_dir,'*_MaxTissueProb_FlipLR')));
        tissue=read_in_2d_csi_mat(tissue_file);
    catch
        gm=-Inf(24,24);
        tissue=-Inf(24,24);
        fprintf('victor code bad\n')
    end
    
    %% increase count if subject has gm at each threshold
    % for each index (p_i) in p
    for prct_i = 1:length(gm_prct)
        if nnz(gm >= gm_prct(prct_i)) >= 1
            subj_cnt(prct_i) = subj_cnt(prct_i)+1;
        end 
        
        % store non-zero count of this subject at this threshold
        ngm_in_here = nnz(gm >= gm_prct(prct_i));
        gm_vox_cnt(prct_i, subj_i) = ngm_in_here;
        
        
    end
    
end


figure;
plot(gm_prct, gm_vox_cnt)