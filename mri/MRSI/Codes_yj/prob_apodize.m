function [parc_comb_prob, mprage_ct, flair_ct, mask_ct, parc_comb_ct] = prob_apodize(...
    CurrentScoutSliceNum, filename_csi_json, B0ScoutThk_resize, parc_comb, mask, mprage, flair, nroi)
% PROB_APODIZE sampel PSF and hanning filter

    %% settings
    % get csi_size,csi_FOV,csi_thk,scout_FOV,scout_thk
    csi_settings = jsondecode(fileread(filename_csi_json));

    h_csi     = csi_settings.csi_size(1) ; w_csi     = csi_settings.csi_size(2);
    h_FOV_csi = csi_settings.csi_FOV(1)  ; w_FOV_csi = csi_settings.csi_FOV(2);
    B0ScoutThk_org = csi_settings.scout_thk;
    csi_thk        = csi_settings.csi_thk;
    slice_profile = [0.0135 0.1839 0.4684 0.7768 0.9700 0.9912 0.9402 0.9384 0.9725 0.9939 0.9994 1.0000 1.0000 1.0000 0.9994 0.9939 0.9725 0.9384 0.9402 0.9912 0.9700 0.7768 0.4684 0.1839 0.0135];

    
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
    if ~isempty(flair)
        flair_ct = flair(:,:,ceil(B0ResizeSliceNum_St)-1:ceil(B0ResizeSliceNum_End)+1);
    else
        flair_ct = [];
    end

    %%% Rotation
    for ss = 1:size(parc_comb_ct,3)
        parc_comb_ct(:,:,ss) = imrotate(parc_comb_ct(:,:,ss), 270);
        mprage_ct(:,:,ss) = imrotate(mprage_ct(:,:,ss), 270);
        mask_ct(:,:,ss) = imrotate(mask_ct(:,:,ss), 270);
        if ~isempty(flair_ct)
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
    parc_comb_ct_psf = zeros(size(parc_comb_ct,1), size(parc_comb_ct,2), size(parc_comb_ct,3), nroi);
    for ss = 1:size(parc_comb_ct,3)
        for rg = 1:nroi
            tmp = double(parc_comb_ct == rg);
            parc_comb_ct_psf(:,:,ss,rg) = conv2(tmp(:,:,ss), HFMAT_Sp, 'same');
        end
        count_psf(:,:,ss) = conv2(count_ct(:,:,ss), HFMAT_Sp, 'same');
    end

    %% Apply slice profile
    parc_comb_ct2 = zeros(size(parc_comb_ct_psf));
    count_ct2 = zeros(size(count_psf));
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
    for rg = 1:nroi
        parc_comb_ct_ext(:,:,:,rg) = extension_one(h_FOV_csi, w_FOV_csi, h_csi, w_csi, parc_comb_ct2(:,:,:,rg));
    end
    count_ct_ext = extension_one(h_FOV_csi, w_FOV_csi, h_csi, w_csi, count_ct2);

    %% Calculate probability
    % [h_ext, w_ext, s_ext] = size(count_ct_ext);
    h_factor = ceil(h_FOV_csi / h_csi);
    w_factor = ceil(w_FOV_csi / w_csi);
    parc_comb_prob = zeros(h_csi,w_csi,nroi);
    count_csi = zeros(h_csi,w_csi);
    for hh = 1:h_csi
        for ww = 1:w_csi
            count_csi(hh,ww) = sum(sum(sum(count_ct_ext((h_factor*(hh-1)+1):(h_factor*hh),(w_factor*(ww-1)+1):(w_factor*ww),:))));
            for rg = 1:nroi
                tmp = parc_comb_ct_ext(:,:,:,rg);
                parc_comb_prob(hh,ww,rg) = sum(sum(sum(tmp((h_factor*(hh-1)+1):(h_factor*hh),(w_factor*(ww-1)+1):(w_factor*ww),:))));            
            end
        end
    end
    for rg = 1:nroi
        parc_comb_prob(:,:,rg) = parc_comb_prob(:,:,rg) ./ count_csi;        
    end

end

