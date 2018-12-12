function csi_roi_label(roi_dir,filename_table,filename_csi_json, filename_flair,ScoutSliceNum)
% csi_roi_overlap Calculate probability of freesurfer rois in csi voxel.
% depends on co-registed-to-slice individual roi nii masks
% (see grouping_mask+spm_reg_ROIs) in roi_dir and enumerated by 
% filename_table (see grouping_mask for desc).
% csi (and b0 scout thickness) settings are read from filename_csi_json
% will write e.g.
%    17_csivoxel_FlipLR.THA
%    17_FractionGM_FlipLR
%    ../17_13_FlipLR.MPRAGE


disp('Calculate fraction GM at CSI position');

%% settings
% get csi_size,csi_FOV,csi_thk,scout_FOV,scout_thk
csi_settings = jsondecode(fileread(filename_csi_json));

h_csi     = csi_settings.csi_size(1) ; w_csi     = csi_settings.csi_size(2);
h_FOV_csi = csi_settings.csi_FOV(1)  ; w_FOV_csi = csi_settings.csi_FOV(2);
h_FOV_sct = csi_settings.scout_FOV(1); w_FOV_sct = csi_settings.scout_FOV(2);
B0ScoutThk_org = csi_settings.scout_thk;
csi_thk        = csi_settings.csi_thk;

B0ScoutThk_resize = 1; % resized B0 scout thickness [mm]

% where are the files?
% data_dir1='some/path/Processed/parc_group/' % in: resamp. rois
%                                             % out: 17_csivoxel.FlipLR.*
% data_dir2='some/path/Processed/' % save .MPRAGE
data_dir1 = roi_dir;
% dir 2 is one above dir1 (parent of roi_dir)
data_dir2 = dirname(roi_dir);


% Are we using flair?
if ~isempty(filename_flair) && exist(filename_flair,'file')
    img_nii = load_untouch_nii(strcat(data_dir,'r',filename_flair));  % input
    flair = img_nii.img;
    FLAIRFlag = 1;
else
    FLAIRFlag = 0;
end


%% read in nifti
img_nii = load_untouch_nii(fullfile(data_dir1,'rorig.nii'));   % input
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
          

%% Match FOV of CSI with that of B0 scout
if (h_FOV_csi < h_FOV_sct)
    diff_FOV = h_FOV_sct - h_FOV_csi;
    if (mod(diff_FOV,2) == 0)
        if (FLAIRFlag == 1)
            flair = flair(1+diff_FOV/2:h_FOV_sct-diff_FOV/2,:,:);
        end
        mprage = mprage(1+diff_FOV/2:h_FOV_sct-diff_FOV/2,:,:);
        prob_4d = prob_4d(1+diff_FOV/2:h_FOV_sct-diff_FOV/2,:,:,:);
    else
        disp('The FOVs of B0 scout and CSI does not match. Because the difference of FOVs is not even number, it should be interpolated.');
        return;
    end
end
if (w_FOV_csi < w_FOV_sct)
    diff_FOV = w_FOV_sct - w_FOV_csi;
    if (mod(diff_FOV,2) == 0)
        if (FLAIRFlag == 1)
            flair = flair(:,1+diff_FOV/2:w_FOV_sct-diff_FOV/2,:);
        end
        mprage = mprage(:,1+diff_FOV/2:w_FOV_sct-diff_FOV/2,:);
        prob_4d = prob_4d(:,1+diff_FOV/2:w_FOV_sct-diff_FOV/2,:,:);
    else
        disp('The FOVs of B0 scout and CSI does not match. Because the difference of FOVs is not even number, it should be interpolated.');
        return;
    end
end

%% Combine segmentation results (Tissue w/ max probability will be chosen. no empty space)
[~, parc_comb] = max(prob_4d, [], 4);
% mask = sum(prob_4d,4) >= 0.6;
mask = sum(prob_4d,4) ~= 0;
parc_comb = parc_comb .* mask;

%% Save as nii format
img_nii.img = parc_comb;
save_untouch_nii(img_nii, fullfile(data_dir1, 'parc_newbin.nii'));

for ind_scout = 1:size(ScoutSliceNum,2)
    CurrentScoutSliceNum = ScoutSliceNum(ind_scout);
    %% Locate CSI slice
    CSICenterPos = (CurrentScoutSliceNum*B0ScoutThk_org - B0ScoutThk_org/2) / B0ScoutThk_resize;  % [mm]
    CSIStPos = CSICenterPos - csi_thk/2;  % [mm]
    CSIEndPos = CSICenterPos + csi_thk/2;  % [mm]
    B0ResizeSliceNum_St = CSIStPos/B0ScoutThk_resize;
    B0ResizeSliceNum_End = CSIEndPos/B0ScoutThk_resize;
    if (B0ResizeSliceNum_St - round(B0ResizeSliceNum_St) == 0)
        B0ResizeSliceNum_St = B0ResizeSliceNum_St + 1;
    end
    parc_comb_ct = parc_comb(:,:,ceil(B0ResizeSliceNum_St)-1:ceil(B0ResizeSliceNum_End)+1);
    mprage_ct = mprage(:,:,ceil(B0ResizeSliceNum_St)-1:ceil(B0ResizeSliceNum_End)+1);
    mask_ct = mask(:,:,ceil(B0ResizeSliceNum_St)-1:ceil(B0ResizeSliceNum_End)+1);
    if (FLAIRFlag == 1)
        flair_ct = flair(:,:,ceil(B0ResizeSliceNum_St)-1:ceil(B0ResizeSliceNum_End)+1);
    end

    %%% Rotation
    for ss = 1:size(parc_comb_ct,3)
        parc_comb_ct(:,:,ss) = imrotate(parc_comb_ct(:,:,ss), 270);
        mprage_ct(:,:,ss) = imrotate(mprage_ct(:,:,ss), 270);
        mask_ct(:,:,ss) = imrotate(mask_ct(:,:,ss), 270);
        if (FLAIRFlag == 1)
            flair_ct(:,:,ss) = imrotate(flair_ct(:,:,ss), 270);
        end
    end
    [h,w,~] = size(parc_comb_ct);
 
    %% Sampling PSF and Hanning filter (apodization)
    hanningon = 1;
    hfsize_h = h_csi;
    hfsize_w = w_csi;
    HFMAT(1:h_csi,1:w_csi) = 0.0;
    if (hanningon==1)
        HFR = hanning(hfsize_h,'periodic');
        HFC = hanning(hfsize_w,'periodic');
        for a=1:length(HFR)
            HFMAT(a,:) = HFC(:)*HFR(a);
        end
    else
        HFMAT(1:h_csi,1:w_csi) = 1.0;
    end
    % figure, imagesc(HFMAT), axis('image'), colormap('gray'), title('Sampling PSF');
    %%% Zero Filling
    HFMAT_MPsz = padarray(HFMAT, [(h-h_csi)/2.0 (w-w_csi)/2.0], 0, 'both');
    % figure, imagesc(HFMAT_MPsz), axis('image'), colormap('gray'), title('Sampling PSF with MPRAGE size');
    %%% FFT Hanning filter to spatial domain
    HFMAT_Sp = abs(ifftshift(ifft2(ifftshift(HFMAT_MPsz))));
    % figure, imagesc(HFMAT_Sp), axis('image'), colormap('gray'), title('Sampling PSF in spatial domain');
    %%% Convolution 
    count_ct = ones(size(parc_comb_ct));
    parc_comb_ct_psf = zeros(size(parc_comb_ct,1), size(parc_comb_ct,2), size(parc_comb_ct,3), size(prob_4d,4));
    for ss = 1:size(parc_comb_ct,3)
        for rg = 1:size(prob_4d,4)
            tmp = double(parc_comb_ct == rg);
            parc_comb_ct_psf(:,:,ss,rg) = conv2(tmp(:,:,ss), HFMAT_Sp, 'same');
        end
        count_psf(:,:,ss) = conv2(count_ct(:,:,ss), HFMAT_Sp, 'same');
    end

    %% Apply slice profile
    parc_comb_ct2 = zeros(size(parc_comb_ct_psf));
    count_ct2 = zeros(size(count_psf));
    slice_profile = [0.0135 0.1839 0.4684 0.7768 0.9700 0.9912 0.9402 0.9384 0.9725 0.9939 0.9994 1.0000 1.0000 1.0000 0.9994 0.9939 0.9725 0.9384 0.9402 0.9912 0.9700 0.7768 0.4684 0.1839 0.0135];
    sp_intpl = interp1(1:size(slice_profile,2),slice_profile,linspace(1,size(slice_profile,2),size(parc_comb_ct_psf,3)));
    for ih = 1:size(parc_comb_ct_psf,1)
        for iw = 1:size(parc_comb_ct_psf,2)
            for rg = 1:size(parc_comb_ct_psf,4)
                parc_comb_ct2(ih,iw,:,rg) = squeeze(parc_comb_ct_psf(ih,iw,:,rg)).' .* sp_intpl;
            end
            count_ct2(ih,iw,:) = squeeze(count_psf(ih,iw,:)).' .* sp_intpl;
        end
    end

    %% Extension
    if (h_FOV_csi ~= size(mprage,1) || w_FOV_csi ~= size(mprage,2))
        disp('FOVs of CSI and B0 scout does not match.')
    end
    for rg = 1:size(prob_4d,4)
        parc_comb_ct_ext(:,:,:,rg) = extension_one(h_FOV_csi, w_FOV_csi, h_csi, w_csi, parc_comb_ct2(:,:,:,rg));
    end
    count_ct_ext = extension_one(h_FOV_csi, w_FOV_csi, h_csi, w_csi, count_ct2);

    %% Calculate probability
    % [h_ext, w_ext, s_ext] = size(count_ct_ext);
    h_factor = ceil(h_FOV_csi / h_csi);
    w_factor = ceil(w_FOV_csi / w_csi);
    parc_comb_prob = zeros(h_csi,w_csi,size(prob_4d,4));
    count_csi = zeros(h_csi,w_csi);
    for hh = 1:h_csi
        for ww = 1:w_csi
            count_csi(hh,ww) = sum(sum(sum(count_ct_ext((h_factor*(hh-1)+1):(h_factor*hh),(w_factor*(ww-1)+1):(w_factor*ww),:))));
            for rg = 1:size(prob_4d,4)
                tmp = parc_comb_ct_ext(:,:,:,rg);
                parc_comb_prob(hh,ww,rg) = sum(sum(sum(tmp((h_factor*(hh-1)+1):(h_factor*hh),(w_factor*(ww-1)+1):(w_factor*ww),:))));            
            end
        end
    end
    for rg = 1:size(prob_4d,4)
        parc_comb_prob(:,:,rg) = parc_comb_prob(:,:,rg) ./ count_csi;        
    end
    
    %% dissect by roi type
    
%   sum_prob = sum(parc_comb_prob,3);  % Whole brain without skull
    sum_prob = sum(parc_comb_prob(:,:,wm_idx | gm_idx),3); % Summation of GM and WM
    disp(sum_prob);

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

    %% combine wm and gm (or any other description) for each roi
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
    parc_lut_fid=fopen(fullfile(data_dir1,'ParcelCSIvoxel_lut.txt'),'w');
    
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
    %parc_csf = sum(parc_comb_prob(:,:,nb_idx),3);  % Brain regions excluding GM and WM
    fraction_gm = parc_gm ./ (parc_gm + parc_wm);
    fraction_gm = fraction_gm .* (parc_csivoxel~=0);
    
    % this is probalby wrong now - but does not seem to be used
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
        if (FLAIRFlag == 1)
            flair_ct(:,:,yj) = fliplr(flair_ct(:,:,yj));
        end
    end
    sum_prob = fliplr(sum_prob);
    fraction_gm = fliplr(fraction_gm);
    parc_csivoxel = fliplr(parc_csivoxel);
    parc_csivoxel_prob = fliplr(parc_csivoxel_prob);
%     for yj = 1:size(fraction_gm_3d,3)
%         fraction_gm_3d(:,:,yj) = fliplr(fraction_gm_3d(:,:,yj));
%     end

    %% write the output image
    % short cut for write_out function defined below using datadir & slice#
    write_out_ds = @(n, d) write_out(d, data_dir1, CurrentScoutSliceNum, n{:});

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

    
    %% probablity for each in the mprage (and flair)
    % write MPRAGE and FLAIR to datadir2
    write_out_ds = @(n, d) write_out(d, data_dir2, CurrentScoutSliceNum, n{:});
    for yj = 1:size(parc_comb_ct,3)
        %name = strcat(data_dir2,num2str(CurrentScoutSliceNum),'_',num2str(yj),'_FlipLR.MPRAGE');
        slice_name = num2str(yj);
        write_out_ds({slice_name, 'FlipLR.MPRAGE'},mprage_ct(:,:,yj));

        if (FLAIRFlag == 1)
            write_out_ds({slice_name, 'FlipLR.FLAIR'}, flair_ct(:,:,yj));
        end
    end

    %% save everything
    save(fullfile(data_dir1, ['parc_at_csi_', num2str(CurrentScoutSliceNum), '.mat']));

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
    
    % write as nifti if we have a csi_template image in the output dir
    % keep the template image around to save time
    persistent tmpl_img
    out_template=fullfile(out_dir,'csi_template.nii');
    if exist(out_template,'file') && isempty(tmpl_img)
        tmpl_img = load_untouch_nii(out_template);
    end
    if ~isempty(tmpl_img)
        tmpl_img.img = rot90(data);
        csi2d_to_nii(data,[name '.nii'],tmpl_img)
    end
end