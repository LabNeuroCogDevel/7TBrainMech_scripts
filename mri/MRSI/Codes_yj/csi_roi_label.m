function csi_roi_label(roi_dir,filename_table,filename_csi_json, filename_flair,ScoutSliceNum)
% csi_roi_overlap Calculate probability of freesurfer rois in csi voxel.
% depends on
%  * co-registed-to-slice individual roi nii masks 
%    (see grouping_mask+spm_reg_ROIs) in roi_dir and enumerated by ...
%  * filename_table (see grouping_mask for desc).
%  * csi (and b0 scout thickness) settings are read from filename_csi_json
% will write e.g.
%    2d_csi_ROI/17_csivoxel_FlipLR.THA % slice_..._ROI (prob)
%    2d_csi_ROI/17_FractionGM_FlipLR   % slice_metric (best roi, max prob,...)
%    struct_ROI/17_13_FlipLR.MPRAGE


disp('Calculate fraction GM at CSI position');

%% settings
% get csi_size,csi_FOV,csi_thk,scout_FOV,scout_thk


B0ScoutThk_resize = 1; % resized B0 scout thickness [mm]


% Are we using flair?
if ~isempty(filename_flair) && exist(filename_flair,'file')
    img_nii = load_untouch_nii(strcat(data_dir,'r',filename_flair));  % input
    flair = img_nii.img;
else
    flair = [];
end

%% output directories
struct_dir = fullfile(roi_dir,'..','struct_ROI');
csi_dir = fullfile(roi_dir,'..','2d_csi_ROI');
if ~exist(struct_dir,'dir'); mkdir(struct_dir); end
if ~exist(csi_dir   ,'dir'); mkdir(csi_dir   ); end

%% read in nifti (slice registred rois)
img_nii = load_untouch_nii(fullfile(roi_dir,'rorig.nii'));   % input
mprage = img_nii.img;
[h,w,s] = size(mprage);

% read in rois, make names like 'rRAcing_wm.nii' and 'rbrainstem.nii'
t = readtable(filename_table,'ReadVariableNames',1);
t = [t rowfun(@name_mask,t(:,{'name','matter'}),'OutputVariable','nii')];
t.nii = cellfun(@(x) ['r' x], t.nii,'UniformOutput',0);
% read in nifti images from nii files defined in table
get_img = @(x) getfield(load_untouch_nii(fullfile(roi_dir,x)),'img');
all_masks = cellfun(get_img, t.nii, 'UniformOutput', 0);
% make into a 4d matrix
prob_4d = permute(reshape(cell2mat(      ...
              all_masks'),               ... 1x26
              [h,w,length(all_masks),s]),... 216x216x26x99
              [1 2 4 3]);                ... 216x216x99x26
          
% check that we did this correctly
% paren = @(x, varargin) x(varargin{:});
% testmasks=[11:15];
% for mii = testmasks
%     [i,j,k]=ind2sub(size(mprage),find(all_masks{mii}));
%     testit=zeros(length(i),1);
%     for ii=1:length(i)
%       testit(ii) = paren(all_masks{mii},i(ii),j(ii),k(ii)) == prob_4d(i(ii),j(ii),k(ii),mii);
%     end
%     all(testit)
% end

% free up some space
clear all_masks

% index the types of brain matter: white, grey, non-brain
wm_idx = strncmp('wm',t.matter,2);
gm_idx = strncmp('gm',t.matter,2);
nb_idx = strncmp('nb',t.matter,2);
% ab_idx = strncmp('abnormal',t.name,8);

%% match grids
[prob_4d, mprage, flair] = ...
    match_B0_CSI(prob_4d, mprage, flair, filename_csi_json);

%% Combine segmentation results (Tissue w/ max probability will be chosen. no empty space)
[~, parc_comb] = max(prob_4d, [], 4);
% mask = sum(prob_4d,4) >= 0.6;
mask = sum(prob_4d,4) ~= 0;
parc_comb = parc_comb .* mask;

% save as nii format
img_nii.img = parc_comb;
save_untouch_nii(img_nii, fullfile(roi_dir, 'parc_newbin.nii'));

%% pull out the segmation each slice individually
for ind_scout = 1:size(ScoutSliceNum,2)
    CurrentScoutSliceNum = ScoutSliceNum(ind_scout);
    
    %% Locate CSI slice, select just that bit
    % Sampling PSF and Hanning filter (apodization)
    % Apply slice profile
    % Calculate probability
    [parc_comb_prob, ...
     mprage_ct, flair_ct, mask_ct, parc_comb_ct] = ...
        prob_apodize(CurrentScoutSliceNum, filename_csi_json, ...
        B0ScoutThk_resize, parc_comb, mask, mprage, flair, size(prob_4d,4));
    
    %% dissect by roi type
    
%   sum_prob = sum(parc_comb_prob,3);  % Whole brain without skull
    sum_prob = sum(parc_comb_prob(:,:,wm_idx | gm_idx),3); % Summation of GM and WM
    %disp(sum_prob);
    %imagesc(sum_prob);

%     %% Divide sub-cortical WM according to GM percentage within the CSI voxel
%     parc_comb_prob_gm = parc_comb_prob;
%     for rg = 1:size(parc_comb_prob,3)
%         if (rg == 2 || rg == 3 || rg == 4 || rg == 6 || rg == 8 || rg == 10 || rg == 12 || rg == 14 || rg == 16 || rg == 18 || rg == 20 || rg == 22 || rg == 24 || rg == 26 || rg == 28)
%             parc_comb_prob_gm(:,:,rg) = zeros(size(parc_comb_prob,1), size(parc_comb_prob,2));
%         end
%     end
%     [tmp,parc_SCWM] = max(parc_comb_prob_gm, [], 3);
%     parc_SCWM = parc_SCWM + 1;
%     parc_prob_SCWM = zeros(size(parc_comb_prob));
%     for rg = 1:size(parc_comb_prob,3)
%         parc_prob_SCWM(:,:,rg) = parc_comb_prob(:,:,14) .* (parc_SCWM == rg);
%     end
%     parc_comb_prob_splitSCWM = parc_comb_prob;
%     parc_comb_prob_splitSCWM(:,:,14) = zeros(size(parc_comb_prob,1), size(parc_comb_prob,2));
%     parc_comb_prob_splitSCWM = parc_comb_prob_splitSCWM + parc_prob_SCWM;
%     parc_comb_prob = parc_comb_prob_splitSCWM;  %% Comment out if you dont want to divide sub-cortical WM

    %% combine wm and gm (or any other not 'nb' description) for each roi
    % cell of vectors, each a roi pair (e.g. 1 and 12 are "abnormal")
    unq_regions = unique(t.name(~nb_idx)); % no non-brain: no brainstem, no csf
    rg_pair_idxs = cellfun(@(tn) strmatch(tn,t.name), unq_regions, 'UniformOutput',0);
    %   >> t(rg_pair_idxs{1},{'name','matter'})
    %         name        matter
    %         'abnormal'    'gm'  
    %         'abnormal'    'wm'
    
    % initialize matrix limited to just pairs
    gmwm_size=size(parc_comb_prob); gmwm_size(3) = length(unq_regions);
    parc_comb_prob_GMWMsum = zeros(gmwm_size);
    % our labels are now in sorted order thanks to 'unique'
    % so lets make sure we know which number is what roi
    parc_lut_fid=fopen(fullfile(csi_dir,'ParcelCSIvoxel_lut.txt'),'w');
    
    for i=1:length(rg_pair_idxs)
        rg_pairs=rg_pair_idxs{i};
        % add region's (wm+gm) pair together
        parc_comb_prob_GMWMsum(:,:,i) = sum(parc_comb_prob(:,:,rg_pairs),3);
        % write to lookup table
        fprintf(parc_lut_fid, '%d\t%s\t%s\n', i, t.name{rg_pairs(1)},t.label{rg_pairs(1)});
    end
    fclose(parc_lut_fid);
    
    [parc_csivoxel_prob, parc_csivoxel] = max(parc_comb_prob_GMWMsum, [], 3);
    

   
% previously with hard coded index and label
% each roi has wm+gm pair (in that order)
% second roi pair (id 3+4) are nonbrain (brainstem and csf)
% thalm and b.g. are gm only, each have zero matrix for wm (idx 26+28)
%     parc_comb_prob_GMWMsum_tmp = zeros(size(parc_comb_prob,1), size(parc_comb_prob,2), size(parc_comb_prob,3)/2);  
%     % sum has 1 less index b/c no bst+csf pair
%     parc_comb_prob_GMWMsum = zeros(size(parc_comb_prob,1), size(parc_comb_prob,2), size(parc_comb_prob,3)/2-1);
%     % summing wm and gm
%     for rg = 1:size(parc_comb_prob_GMWMsum_tmp,3)
%         parc_comb_prob_GMWMsum_tmp(:,:,rg) = parc_comb_prob(:,:,rg*2-1) + parc_comb_prob(:,:,rg*2);
%     end
%     % Exclude brainstem and csf (pair, so only skip one idx)
%     parc_comb_prob_GMWMsum(:,:,1) = parc_comb_prob_GMWMsum_tmp(:,:,1);
%     parc_comb_prob_GMWMsum(:,:,2:end) = parc_comb_prob_GMWMsum_tmp(:,:,3:end);
%     clear parc_comb_prob_GMWMsum_tmp;
% 
%     [parc_csivoxel_prob, parc_csivoxel] = max(parc_comb_prob_GMWMsum, [], 3);

    %% sum up regions
    parc_gm  = sum(parc_comb_prob(:,:,gm_idx),3);
    parc_wm  = sum(parc_comb_prob(:,:,wm_idx),3);
    fraction_gm = parc_gm ./ (parc_gm + parc_wm); 
    % % N.B. no parc_csf -- in initial code, but parc_csf is coded
    % % using csf throws off values!?
    % parc_csf = sum(parc_comb_prob(:,:,nb_idx),3);% Brain regions excluding GM and WM
    % fraction_gm = parc_gm ./ (parc_gm + parc_wm + parc_csf); 
    % OR
    %parc_ngm = sum(parc_comb_prob(:,:,~gm_idx),3);
    %fraction_gm = parc_gm ./ (parc_gm + parc_ngm);
    
    fraction_gm = fraction_gm .* (parc_csivoxel~=0);
    
    % this is probalby wrong now - but does not seem to be used
    % now == swtich from wm,gm index counting to table w/ labels
%     fraction_gm_3d = zeros(size(parc_comb_prob_GMWMsum));
%     for rg = 1:size(fraction_gm_3d,3)
%         fraction_gm_3d(:,:,rg) = double(parc_csivoxel == rg) .* fraction_gm;
%     end

    %% Flip R-L
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
    sum_prob = fliplr(sum_prob);
    fraction_gm = fliplr(fraction_gm);
    parc_csivoxel = fliplr(parc_csivoxel);
    parc_csivoxel_prob = fliplr(parc_csivoxel_prob);
% simliiar to above. probalby wrong now, but not used
%     for yj = 1:size(fraction_gm_3d,3)
%         fraction_gm_3d(:,:,yj) = fliplr(fraction_gm_3d(:,:,yj));
%     end

    %% write the output image
    % short cut for write_out function defined below using datadir & slice#
    if ~exist(csi_dir,'dir'); mkdir(csi_dir); end
    write_out_ds = @(n, d) write_out(d, csi_dir, CurrentScoutSliceNum, n{:});

    % save each roi's prob
    for rg = 1:size(prob_4d,4)
        label = ['FlipLR.' char(t.label{rg})]; 
        write_out_ds({'csivoxel',label}, parc_comb_prob(:,:,rg));
        % writes e.g. 17_csivoxel_FlipLR.THA into data_dir1
    end
    % save each calculated matrix
    % e.g. 17_FractionGM_FlipLR
    write_out_ds({'FractionGM','FlipLR'}, fraction_gm);   
    write_out_ds({'ParcelCSIvoxel','FlipLR'}, parc_csivoxel);
    write_out_ds({'SumProb','FlipLR'},sum_prob);
    write_out_ds({'MaxTissueProb','FlipLR'},parc_csivoxel_prob);

    
    %% roi for each in the mprage (and flair)
    % write MPRAGE and FLAIR to parent of roi_dir
    write_out_ds = @(n, d) write_out(d, struct_dir, CurrentScoutSliceNum, n{:});
    for yj = 1:size(parc_comb_ct,3)
        %name = strcat(data_dir2,num2str(CurrentScoutSliceNum),'_',num2str(yj),'_FlipLR.MPRAGE');
        slice_name = num2str(yj);
        write_out_ds({slice_name, 'FlipLR.MPRAGE'},mprage_ct(:,:,yj));

        if ~isempty(flair_ct)
            write_out_ds({slice_name, 'FlipLR.FLAIR'}, flair_ct(:,:,yj));
        end
    end

    %% save everything
    save(fullfile(roi_dir, ['parc_at_csi_', num2str(CurrentScoutSliceNum), '.mat']));

    %% figure
%     slice_num = 6;
%     figure, imagesc(flipud(mprage_ct(:,:,slice_num))), axis('image'), colormap('gray'), title('MPRAGE, center slice');
%     if (FLAIRFlag == 1)
%         figure, imagesc(flipud(flair_ct(:,:,slice_num))), axis('image'), colormap('gray'), title('FLAIR, center slice');
%     end
%     figure, imagesc(flipud(parc_comb_ct(:,:,slice_num))), axis('image'), title('Parcellated result, center slice');
%     figure, imagesc(flipud(mask_ct(:,:,slice_num))), axis('image'), colormap('gray'), title('Mask, center slice');
%     figure, imagesc(flipud(sum_prob)), axis('image'), colormap('gray'), title('Sum of probability');
%     figure, imagesc(flipud(parc_csivoxel)), axis('image'), title('Subgrouped (GM/WM Merged), CSI voxel');
%     figure, imagesc(flipud(parc_csivoxel_prob)), axis('image'), colormap('gray'), title('Percentage of max subgroup (GM/WM Merged), CSI voxel');
%     figure, imagesc(flipud(fraction_gm)), axis('image'), colormap('gray'), title('Fraction GM, CSI voxel');

end
end

function write_out(data,out_dir,slice_num, varargin)
    name = strjoin([ {num2str(slice_num)} ,varargin],'_');
    name = fullfile(out_dir,name);
    fid = fopen(name, 'w');
    fwrite(fid, data, 'float');
    fclose(fid);
    
% %%% use dir2d_to_niis instead
%     % write as nifti if we have a csi_template image in proc dir (parent of
%     % out)
%     % keep the template image around to save time
%     persistent tmpl_img
%     out_template=fullfile(dirname(out_dir),'csi_template.nii');
%     if exist(out_template,'file') && isempty(tmpl_img)
%         tmpl_img = load_untouch_nii(out_template);
%     end
%     if ~isempty(tmpl_img)
%         tmpl_img.img = rot90(data);
%         csi2d_to_nii(data,[name '.nii'],tmpl_img)
%     end
end