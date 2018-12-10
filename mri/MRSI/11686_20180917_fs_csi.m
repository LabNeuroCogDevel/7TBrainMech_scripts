addpath('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/Codes_yj//NIfTI');
addpath('/opt/ni_tools/matlab_toolboxes/spm12/');

matlabcode_dir='/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/Codes_yj/';
ROI_dir='/Volumes/Hera/Projects/7TBrainMech/subjs/11686_20180917/slice_PFC/MRSI/Processed/parc_group';
data_dir='/Volumes/Hera/Projects/7TBrainMech/subjs/11686_20180917/slice_PFC/MRSI';
filename_scout='scout.nii';

cd(matlabcode_dir);
parc_grouping_ft_plusExtras(ROI_dir);
img_resize_ft('/Volumes/Hera/Projects/7TBrainMech/subjs/11686_20180917/slice_PFC/MRSI','scout.nii');
spm_registration_ROI_ft_plusExtras(matlabcode_dir,ROI_dir,data_dir,filename_scout,0,'0');

parc_at_csi_multi_ft_plusExtras('/Volumes/Hera/Projects/7TBrainMech/subjs/11686_20180917/slice_PFC/MRSI',...
    0,'0',... flair
    [13.7,17,20.3,23.7], ... scout slice number
    [24,24],     ... csi: size
    [240,240],8, ... csi: fov, thk
    [240,240],3);... scout: fov, thk
    

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
