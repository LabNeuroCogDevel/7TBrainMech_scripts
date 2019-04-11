function[row_of_max, col_of_max]= gmmax_vox_tis(parc_comb, fracgm, fractis, plotroi)
% gmmax_vox - get max vox in roi using gray matter fraction
% inputs:
% parc_comb_prob - fraction of pixel in roi 24 x 24 x nroi
% gmfrac  - 24 x 24 matrix with fraction of pixel in gm
% plotroi - plotrois?

% USAGE: 
%  s1=subject_files('20180223Luna1');
%  parc_comb = csi_vox_probcomb(s{3});
%  fracgm = read_in_2d_csi_mat(s{3}.fracgm_file);
%  gmmax_vox(parc_comb, fracgm, 0);

fprintf('thresholding of mean %f\n', mean(fracgm(:)))
% use parc_comb_prob to get nroi
if(nargin < 4), plotroi=0; end
%  nzmean is mean of verything > .001
nzmean = @(x) mean(x(abs(x)>10^-3));

nroi=size(parc_comb,3);
%% get max index and value of ROI
row_of_max=zeros(nroi,1);
col_of_max=zeros(nroi,1);

for roi_num=1:nroi
    roi_comb_prob=parc_comb(:,:,roi_num);
    
    %% masking
    % consider:
    %  * roi_comb_prob by gmfrac > threshold?
    %  * gmfrac masked by roi_comb_prob at some thresh
    if plotroi
         figure
         subplot(2,2,1); imagesc(roi_comb_prob);
         subplot(2,2,2); imagesc(fracgm);
         subplot(2,2,3); imagesc((fracgm>=nzmean(fracgm(:))) .* roi_comb_prob);
         subplot(2,2,4); imagesc((roi_comb_prob>=nzmean(roi_comb_prob(:))) .* fracgm);
    end
    thresh = 0.5;
    thresh_tis = 0.1;
    mask = fracgm>=thresh;
    roi_mask_by_gm = mask.* roi_comb_prob;
    mask_tis = fractis>=thresh_tis;
    roi_mask_by_tis = mask_tis.* roi_mask_by_gm;
  
    
    [parc_max,parc_idx] = max(roi_mask_by_tis(:));
    [row_of_max(roi_num),col_of_max(roi_num)] = ind2sub(size(parc_comb), parc_idx);
    fprintf( 'nvox %d, ngm %d, ntis %d, good values in tissue %d, roi %d, max value %d, max in tissue %d\n', numel(mask),nnz(mask(:)), nnz(mask_tis(:)), nnz(roi_mask_by_tis(:)>10^-3), roi_num, max(roi_comb_prob(:)), parc_max)
end

%voxel = d.Row==row_of_max&d.Col==col_of_max;
%d.GABA_Cre(voxel)

end

