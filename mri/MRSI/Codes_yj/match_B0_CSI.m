function [prob_4d, mprage, flair] = ...
    match_B0_CSI(prob_4d, mprage,flair, filename_csi_json)

csi_settings = jsondecode(fileread(filename_csi_json));

h_FOV_csi = csi_settings.csi_FOV(1)  ; w_FOV_csi = csi_settings.csi_FOV(2);
h_FOV_sct = csi_settings.scout_FOV(1); w_FOV_sct = csi_settings.scout_FOV(2);

%% Match FOV of CSI with that of B0 scout
if (h_FOV_csi < h_FOV_sct)
    diff_FOV = h_FOV_sct - h_FOV_csi;
    if (mod(diff_FOV,2) == 0)
        if ~isempty(flair)
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
        if ~isempty(flair)
            flair = flair(:,1+diff_FOV/2:w_FOV_sct-diff_FOV/2,:);
        end
        mprage = mprage(:,1+diff_FOV/2:w_FOV_sct-diff_FOV/2,:);
        prob_4d = prob_4d(:,1+diff_FOV/2:w_FOV_sct-diff_FOV/2,:,:);
    else
        disp('The FOVs of B0 scout and CSI does not match. Because the difference of FOVs is not even number, it should be interpolated.');
        return;
    end
end

end

