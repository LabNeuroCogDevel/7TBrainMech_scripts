function prob_4d = idv_nii_to4d(roi_dir, filenames_cell)
   % IDV_NII_TO4D   mash together individual nifti images into a 4d matrix
   %     roi_dir is the directory where all niftis are stored
   %     filenames_cell is like {'rroi3.nii','rroi4.nii'}
   %       * input niis are likely the files output from spm_reg_ROIs
   %       * expects all niis to have the same matrix dims 
   %     implemented with 26 roi images of size 216x216x99
   %     output 4d is input nifti: 216x216x99x26
   %     output goes to match_B0_CSI and prob_apodize
   get_img = @(x) getfield(load_untouch_nii(fullfile(roi_dir,x)),'img');
   all_masks = cellfun(get_img, filenames_cell, 'UniformOutput', 0);

   % make sure all the masks have the same dimensions
   img_sizes = cell2mat(cellfun(@size, all_masks, 'UniformOutput', 0)'); % [ 216 216 99; 216 216 99; ...]
   sz = unique(img_sizes,'row');
   if size(sz, 1) ~= 1
      disp(sz);
      error('input rois are not all the same size!')
   end

   % get dims
   h=sz(1); w=sz(2); s=sz(3);
   nroi = length(filenames_cell);
   prob_4d=zeros(h,w,s,nroi);
   for ri = 1:nroi
       prob_4d(:,:,:,ri) = all_masks{ri};
   end

%    % make into a 4d matrix
%    % cell2mat puts the 4th dim where we expect the 3rd to be
%    % ready for match_B0_CSI and prob_apodize
%    prob_4d = permute(reshape(cell2mat(      ...
%                  all_masks'),               ... 1x26
%                  [h,w,length(all_masks),s]),... 216x216x26x99
%                  [1 2 4 3]);                ... 216x216x99x26

  % remove NANs
  prob_4d(isnan(prob_4d) ) = 0;
end
