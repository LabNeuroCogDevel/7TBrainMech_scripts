function[row_of_max, col_of_max]= max_vox(parc_comb_prob, nroi)

%% get max index and value of ROI
row_of_max=zeros(nroi,1);
col_of_max=zeros(nroi,1);

for roi_num=1:nroi
    roi_comb_prob=parc_comb_prob(:,:,roi_num);
    [parc_max,parc_idx] = max(roi_comb_prob(:));
    [row_of_max(roi_num),col_of_max(roi_num)] = ind2sub(size(parc_comb_prob), parc_idx);
end

%voxel = d.Row==row_of_max&d.Col==col_of_max;
%d.GABA_Cre(voxel)

end

