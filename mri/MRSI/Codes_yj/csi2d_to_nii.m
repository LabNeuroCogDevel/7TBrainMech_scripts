function csi2d_to_nii(data, name, tmpl_img)
% CSI2d_TO_NII write as nifti if we have a csi_template image in the output dir
%
% ddir = '/Volumes/Hera/Projects/7TBrainMech/subjs/11686_20180917/slice_PFC/MRSI/Processed/parc_group_v4'
% qnii=@(n) csi2d_to_nii(fullfile(ddir,n), fullfile(ddir,[n '.nii']), fullfile(ddir,'csi_template.nii'))
% qnii('17_ParcelCSIvoxel_FlipLR')

    % inputs can be file names
    if isa(data,'char')
        data=read_in_2d_csi_mat(data);
    end
    if isa(tmpl_img,'char')
        tmpl_img = load_untouch_nii(tmpl_img);
    end
    
    % set data
    tmpl_img.hdr.dime.datatype = 16; % force float
    tmpl_img.img = rot90(data);
    tmpl_img.hdr.dime.glmax = max(max(data)); % afni still doesn't see new max
    tmpl_img.ext.section.edata=''; % clear afni notes
    
    % write output
    save_untouch_nii(tmpl_img, name);
end

