addpath('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/Codes_yj/NIfTI');
addpath('/opt/ni_tools/matlab_toolboxes/spm12/');

matlabcode_dir='/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/Codes_yj/';
roi_file='/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/roi.txt';
csi_json='/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/csi_settings.json';

ROI_dir='/Volumes/Hera/Projects/7TBrainMech/subjs/11686_20180917/slice_PFC/MRSI/parc_group';
data_dir='/Volumes/Hera/Projects/7TBrainMech/subjs/11686_20180917/slice_PFC/MRSI';
filename_scout='scout.nii';

cd(matlabcode_dir);
grouping_masks(roi_file, ROI_dir) 
%previously: parc_grouping_ft_plusExtras(ROI_dir)
img_resize_ft(data_dir,filename_scout);

spm_reg_ROIs(ROI_dir, roi_file, fullfile(data_dir,filename_scout), '') 
% previously: spm_registration_ROI_ft_plusExtras(matlabcode_dir,ROI_dir,data_dir,filename_scout,0,'0')

csi_roi_label(ROI_dir,roi_file,csi_json, '',17)

csi_2d_dir = fullfile(data_dir,'2d_csi_ROI');

csi_template = fullfile(data_dir,'csi_template.nii');
dir2d_to_niis(csi_2d_dir,csi_2d_dir,csi_template);




outdir = fullfile(data_dir,'csi_val');
csi_csv = '/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/20180216Luna1/SI1/spreadsheet.csv';
SI1_to_nii(csi_csv,csi_template,outdir);


% previously
% parc_at_csi_multi_ft_plusExtras(data_dir,...
%     0,'0',       ... flair
%     17,          ... scout slice number
%     [24,24],     ... csi: size
%     [216,216],10,... csi: fov, thk
%     [216,216],3);... scout: fov, thk
    
    

% datadir=/Volumes/Hera/Projects/7TBrainMech/subjs/11686_20180917/slice_PFC/MRSI/
% 3dinfo -n4 -ad3 $datadir/{scout*,Processed/parc_group/rorig}.nii|awk '{gsub(".*/","",$NF); print}'
%  128 128 33 1 1.687500 1.687500 3.000001 scout.nii
%  216 216 99 1 1.000000 1.000000 1.000000 scout_resize.nii
%  216 216 99 1 1.000000 1.000000 1.000000 rorig.nii

% scout is from /Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/11686_20180917/0025_B0Scout33Slice_66
% (/Volumes/Hera/Projects/7TBrainMech/subjs/11686_20180917/slice_PFC/slice_pfc.nii.gz)

% dicom_hdr  /Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/11686_20180917/0025_B0Scout33Slice_66/201880917LUNA1_11686.MR.TIEJUN_JREF-LUNA.0025.0033.2018.09.21.13.34.55.140625.95568868.IMA
% 0018 0050        2 [1494    ] //            ACQ Slice Thickness//3 
% 0051 100b        8 [89264   ] //                               //128*128 
% 0051 100c       12 [89280   ] //                               //FoV 216*216
