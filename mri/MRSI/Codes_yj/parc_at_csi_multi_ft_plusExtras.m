function parc_at_csi_multi_ft_plusExtras(data_dir,FLAIRFlag,filename_flair,ScoutSliceNum,csi_size,csi_FOV,csi_thk,scout_FOV,scout_thk)

disp('Calculate fraction GM at CSI position');

% clear all
% data_dir = '/Users/yoojin/Desktop/MRResearch/MRData/MRSI/20150408_PND_Ctrl';  % input
% FLAIRFlag = 1;
% filename_flair = 'AXIALFLAIRs007a1001.nii';
% ScoutSliceNum = [10,16,22,28];
% csi_size = [24,24];
% csi_FOV = [240,240];
% csi_thk = 10;
% scout_FOV = [240,240];
% scout_thk = 4;

h_csi = csi_size(1);
w_csi = csi_size(2);
h_FOV_csi = csi_FOV(1);
w_FOV_csi = csi_FOV(2);
h_FOV_sct = scout_FOV(1);
w_FOV_sct = scout_FOV(2);
B0ScoutThk_org = scout_thk;

B0ScoutThk_resize = 1; % resized B0 scout thickness [mm]
data_dir = strcat(data_dir,'/');
if (FLAIRFlag == 1)
    img_nii = load_untouch_nii(strcat(data_dir,'r',filename_flair));  % input
    flair = img_nii.img;
end

%% Read parcellation results from freesurfer
data_dir1 = strcat(data_dir, 'Processed/parc_group/');
data_dir2 = strcat(data_dir, 'Processed/');
if exist(data_dir2) == 0
    mkdir(data_dir2);
end

img_nii = load_untouch_nii(strcat(data_dir1,'rorig.nii'));   % input
mprage = img_nii.img;
[h,w,s] = size(mprage);
prob_4d = zeros(h,w,s,28);  % 18+10=28: Number of subgroup regions including 3 cingulate regions, thalamus and basal ganglia, and their corresponding WM (zeros for THA and BGA).
img_nii = load_untouch_nii(strcat(data_dir1, 'rabnormal_gm.nii'));
prob_4d(:,:,:,1) = img_nii.img;  % rabnormal_gm
img_nii = load_untouch_nii(strcat(data_dir1, 'rabnormal_wm.nii'));
prob_4d(:,:,:,2) = img_nii.img;  % rabnormal_wm
img_nii = load_untouch_nii(strcat(data_dir1, 'rbrainstem.nii'));
prob_4d(:,:,:,3) = img_nii.img;  % rbrainstem
img_nii = load_untouch_nii(strcat(data_dir1, 'rcsf.nii'));
prob_4d(:,:,:,4) = img_nii.img;  % rcsf
img_nii = load_untouch_nii(strcat(data_dir1, 'rfrontal_gm.nii'));
prob_4d(:,:,:,5) = img_nii.img;  % rfrontal_gm
img_nii = load_untouch_nii(strcat(data_dir1, 'rfrontal_wm.nii'));
prob_4d(:,:,:,6) = img_nii.img;  % rfrontal_wm
img_nii = load_untouch_nii(strcat(data_dir1, 'rinsula_gm.nii'));
prob_4d(:,:,:,7) = img_nii.img;  % rinsula_gm
img_nii = load_untouch_nii(strcat(data_dir1, 'rinsula_wm.nii'));
prob_4d(:,:,:,8) = img_nii.img;  % rinsula_wm
img_nii = load_untouch_nii(strcat(data_dir1, 'roccipital_gm.nii'));
prob_4d(:,:,:,9) = img_nii.img;  % roccipital_gm
img_nii = load_untouch_nii(strcat(data_dir1, 'roccipital_wm.nii'));
prob_4d(:,:,:,10) = img_nii.img;  % roccipital_wm
img_nii = load_untouch_nii(strcat(data_dir1, 'rparietal_gm.nii'));
prob_4d(:,:,:,11) = img_nii.img;  % rparietal_gm
img_nii = load_untouch_nii(strcat(data_dir1, 'rparietal_wm.nii'));
prob_4d(:,:,:,12) = img_nii.img;  % rparietal_wm
img_nii = load_untouch_nii(strcat(data_dir1, 'rsubcortical_gm.nii'));
prob_4d(:,:,:,13) = img_nii.img;  % rsubcortical_gm
img_nii = load_untouch_nii(strcat(data_dir1, 'rsubcortical_wm.nii'));
prob_4d(:,:,:,14) = img_nii.img;  % rsubcortical_wm
img_nii = load_untouch_nii(strcat(data_dir1, 'rtemporal_lateral_gm.nii'));
prob_4d(:,:,:,15) = img_nii.img;  % rtemporal_lateral_gm
img_nii = load_untouch_nii(strcat(data_dir1, 'rtemporal_lateral_wm.nii'));
prob_4d(:,:,:,16) = img_nii.img;  % rtemporal_lateral_wm
img_nii = load_untouch_nii(strcat(data_dir1, 'rtemporal_medial_gm.nii'));
prob_4d(:,:,:,17) = img_nii.img;  % rtemporal_medial_gm
img_nii = load_untouch_nii(strcat(data_dir1, 'rtemporal_medial_wm.nii'));
prob_4d(:,:,:,18) = img_nii.img;  % rtemporal_medial_wm
img_nii = load_untouch_nii(strcat(data_dir1, 'rCAcing_gm.nii'));
prob_4d(:,:,:,19) = img_nii.img;  % caudalanteriorcingulate_gm
img_nii = load_untouch_nii(strcat(data_dir1, 'rCAcing_wm.nii'));
prob_4d(:,:,:,20) = img_nii.img;  % caudalanteriorcingulate_wm
img_nii = load_untouch_nii(strcat(data_dir1, 'rRAcing_gm.nii'));
prob_4d(:,:,:,21) = img_nii.img;  % rostralanteriorcingulate_gm
img_nii = load_untouch_nii(strcat(data_dir1, 'rRAcing_wm.nii'));
prob_4d(:,:,:,22) = img_nii.img;  % rostralanteriorcingulate_wm
img_nii = load_untouch_nii(strcat(data_dir1, 'rPIcing_gm.nii'));
prob_4d(:,:,:,23) = img_nii.img;  % posterior+isthmuscingulate_gm
img_nii = load_untouch_nii(strcat(data_dir1, 'rPIcing_wm.nii'));
prob_4d(:,:,:,24) = img_nii.img;  % posterior+isthmuscingulate_wm
img_nii = load_untouch_nii(strcat(data_dir1, 'rthalamus.nii'));
prob_4d(:,:,:,25) = img_nii.img;  % thalamus
prob_4d(:,:,:,26) = zeros(size(img_nii));
img_nii = load_untouch_nii(strcat(data_dir1, 'rbasal_ganglia.nii'));
prob_4d(:,:,:,27) = img_nii.img;  % basal ganglia
prob_4d(:,:,:,28) = zeros(size(img_nii));
region_label = {'AGM'; 'AWM'; 'BS'; 'CSFP'; 'FGM'; 'FWM'; 'IGM'; 'IWM'; 'OGM'; 'OWM'; 'PGM'; 'PWM'; 'SCGM'; 'SCWM'; 'TLGM'; 'TLWM'; 'TMGM'; 'TMWM'; 'CACGM'; 'CACWM'; 'RACGM'; 'RACWM'; 'PICGM'; 'PICWM'; 'THA'; 'THAwm'; 'BGA'; 'BGAwm'}; 

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
[tmp,parc_comb] = max(prob_4d, [], 4);
% mask = sum(prob_4d,4) >= 0.6;
mask = sum(prob_4d,4) ~= 0;
parc_comb = parc_comb .* mask;

%% Save as nii format
img_nii.img = parc_comb;
save_untouch_nii(img_nii, strcat(data_dir1, 'parc_newbin.nii'));

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
    [h,w,s] = size(parc_comb_ct);
 
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
    [h_ext, w_ext, s_ext] = size(count_ct_ext);
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
%     sum_prob = sum(parc_comb_prob,3);  % Whole brain without skull
    sum_prob = sum(parc_comb_prob(:,:,1:2),3) + sum(parc_comb_prob(:,:,5:end),3);  % Summation of GM and WM

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

    parc_comb_prob_GMWMsum_tmp = zeros(size(parc_comb_prob,1), size(parc_comb_prob,2), size(parc_comb_prob,3)/2);  
    parc_comb_prob_GMWMsum = zeros(size(parc_comb_prob,1), size(parc_comb_prob,2), size(parc_comb_prob,3)/2-1);
    for rg = 1:size(parc_comb_prob_GMWMsum_tmp,3)
        parc_comb_prob_GMWMsum_tmp(:,:,rg) = parc_comb_prob(:,:,rg*2-1) + parc_comb_prob(:,:,rg*2);
    end
    parc_comb_prob_GMWMsum(:,:,1) = parc_comb_prob_GMWMsum_tmp(:,:,1);
    parc_comb_prob_GMWMsum(:,:,2:end) = parc_comb_prob_GMWMsum_tmp(:,:,3:end);  % Exclude brainstem and csf
    clear parc_comb_prob_GMWMsum_tmp;

    [parc_csivoxel_prob, parc_csivoxel] = max(parc_comb_prob_GMWMsum, [], 3);

    parc_gm = parc_comb_prob(:,:,1) + sum(parc_comb_prob(:,:,5:2:end),3);
    parc_wm = parc_comb_prob(:,:,2) + sum(parc_comb_prob(:,:,6:2:end),3);
    parc_csf = parc_comb_prob(:,:,3) + parc_comb_prob(:,:,4);  % Brain regions excluding GM and WM
    fraction_gm = parc_gm ./ (parc_gm + parc_wm);
    fraction_gm = fraction_gm .* (parc_csivoxel~=0);
    fraction_gm_3d = zeros(size(parc_comb_prob_GMWMsum));
    for rg = 1:size(fraction_gm_3d,3)
        fraction_gm_3d(:,:,rg) = double(parc_csivoxel == rg) .* fraction_gm;
    end

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
    for yj = 1:size(fraction_gm_3d,3)
        fraction_gm_3d(:,:,yj) = fliplr(fraction_gm_3d(:,:,yj));
    end

    % write the output image
    for rg = 1:size(prob_4d,4)
        name = strcat(data_dir1,num2str(CurrentScoutSliceNum),'_csivoxel_FlipLR.',char(region_label(rg)));
        fp = fopen(name,'w');
        fwrite(fp,parc_comb_prob(:,:,rg),'float');
        fclose(fp);
    end
    name = strcat(data_dir1,num2str(CurrentScoutSliceNum),'_FractionGM_FlipLR');
    fp = fopen(name,'w');
    fwrite(fp,fraction_gm,'float');
    fclose(fp);

    name = strcat(data_dir1,num2str(CurrentScoutSliceNum),'_ParcelCSIvoxel_FlipLR');
    fp = fopen(name,'w');
    fwrite(fp,parc_csivoxel,'float');
    fclose(fp);

    name = strcat(data_dir1,num2str(CurrentScoutSliceNum),'_SumProb_FlipLR');
    fp = fopen(name,'w');
    fwrite(fp,sum_prob,'float');
    fclose(fp);

    name = strcat(data_dir1,num2str(CurrentScoutSliceNum),'_MaxTissueProb_FlipLR');
    fp = fopen(name,'w');
    fwrite(fp,parc_csivoxel_prob,'float');
    fclose(fp);
    
    for yj = 1:size(parc_comb_ct,3)
        name = strcat(data_dir2,num2str(CurrentScoutSliceNum),'_',num2str(yj),'_FlipLR.MPRAGE');
        fp = fopen(name,'w');
        fwrite(fp,mprage_ct(:,:,yj),'float');
        fclose(fp);

        if (FLAIRFlag == 1)
            name = strcat(data_dir1,num2str(CurrentScoutSliceNum),'_',num2str(yj),'_FlipLR.FLAIR');
            fp = fopen(name,'w');
            fwrite(fp,flair_ct(:,:,yj),'float');
            fclose(fp);
        end
    end

    save(strcat(data_dir1, 'parc_at_csi_', num2str(CurrentScoutSliceNum), '.mat'));

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
