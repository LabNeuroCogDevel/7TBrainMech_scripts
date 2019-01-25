function prob_4d = idv_nii_to_4d(roi_dir, filenames_cell, h, w, s)
   get_img = @(x) getfield(load_untouch_nii(fullfile(roi_dir,x)),'img');
   all_masks = cellfun(get_img, filenames_cell, 'UniformOutput', 0);
   % make into a 4d matrix
   prob_4d = permute(reshape(cell2mat(      ...
                 all_masks'),               ... 1x26
                 [h,w,length(all_masks),s]),... 216x216x26x99
                 [1 2 4 3]);                ... 216x216x99x26
end
