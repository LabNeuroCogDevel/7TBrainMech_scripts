function parc_grouping_ft_plusExtras(dir_MPRAGE)

disp('Grouping parcellated brain into multiple ROIs');

% dir_MPRAGE = '/Users/yoojin/Desktop/MRResearch/MRData/MRSI/20150112_FUB_Ctrl/parc_group/';  % input
dir_MPRAGE = strcat(dir_MPRAGE,'/');
img_nii = load_untouch_nii(strcat(dir_MPRAGE,'aparc+aseg.nii'));
parc_gm = img_nii.img;
img_nii = load_untouch_nii(strcat(dir_MPRAGE,'wmparc.nii'));
parc_wm = img_nii.img;

% [frontal_gm, pixnum_frontal_gm] = ROI_from_Parcel(parc_gm, [1002 1003 1012 1014 1017 1018 1019 1020 1024 1026 1027 1028 1032 2002 2003 2012 2014 2017 2018 2019 2020 2024 2026 2027 2028 2032]);
[frontal_gm, pixnum_frontal_gm] = ROI_from_Parcel(parc_gm, [1003 1012 1014 1017 1018 1019 1020 1024 1027 1028 1032 2003 2012 2014 2017 2018 2019 2020 2024 2027 2028 2032]);
[frontal_wm1, pixnum_frontal_wm1] = ROI_from_Parcel(parc_gm, [252 253 254 255 1004 2004]);
% [frontal_wm2, pixnum_frontal_wm2] = ROI_from_Parcel(parc_wm, [3002 3003 3004 3012 3014 3017 3018 3019 3020 3024 3026 3027 3028 3032 4002 4003 4004 4012 4014 4017 4018 4019 4020 4024 4026 4027 4028 4032]);
[frontal_wm2, pixnum_frontal_wm2] = ROI_from_Parcel(parc_wm, [3003 3004 3012 3014 3017 3018 3019 3020 3024 3027 3028 3032 4003 4004 4012 4014 4017 4018 4019 4020 4024 4027 4028 4032]);
frontal_wm = double(or(frontal_wm1,frontal_wm2));
pixnum_frontal_wm = pixnum_frontal_wm1 + pixnum_frontal_wm2;
clear frontal_wm1 frontal_wm2 pixnum_frontal_wm1 pixnum_frontal_wm2;
gmwm_combined = frontal_gm .* frontal_wm;
if (max(gmwm_combined(:)) ~= 0)
    disp('There is an overlapped region with both WM and GM in frontal. Needed to be checked.')
end
img_nii.img = frontal_gm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'frontal_gm.nii'));
img_nii.img = frontal_wm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'frontal_wm.nii'));

% caudalanteriorcingulate and rostralanteriorcingulate separated from frontal
[CAcing_gm, pixnum_CAcing_gm] = ROI_from_Parcel(parc_gm, [1002 2002]);
[CAcing_wm, pixnum_CAcing_wm] = ROI_from_Parcel(parc_wm, [3002 4002]);
gmwm_combined = CAcing_gm .* CAcing_wm;
if (max(gmwm_combined(:)) ~= 0)
    disp('There is an overlapped region with both WM and GM in CAcing. Needed to be checked.')
end
img_nii.img = CAcing_gm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'CAcing_gm.nii'));
img_nii.img = CAcing_wm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'CAcing_wm.nii'));


[RAcing_gm, pixnum_RAcing_gm] = ROI_from_Parcel(parc_gm, [1026 2026]);
[RAcing_wm, pixnum_RAcing_wm] = ROI_from_Parcel(parc_wm, [3026 4026]);
gmwm_combined = RAcing_gm .* RAcing_wm;
if (max(gmwm_combined(:)) ~= 0)
    disp('There is an overlapped region with both WM and GM in RAcing. Needed to be checked.')
end
img_nii.img = RAcing_gm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'RAcing_gm.nii'));
img_nii.img = RAcing_wm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'RAcing_wm.nii'));

% [parietal_gm, pixnum_parietal_gm] = ROI_from_Parcel(parc_gm, [1005 1008 1022 1023 1025 1029 1031 2005 2008 2022 2023 2025 2029 2031]);
[parietal_gm, pixnum_parietal_gm] = ROI_from_Parcel(parc_gm, [1005 1008 1022 1025 1029 1031 2005 2008 2022 2025 2029 2031]);
[parietal_wm1, pixnum_parietal_wm1] = ROI_from_Parcel(parc_gm, 251);
% [parietal_wm2, pixnum_parietal_wm2] = ROI_from_Parcel(parc_wm, [3005 3008 3022 3023 3025 3029 3031 4005 4008 4022 4023 4025 4029 4031]);
[parietal_wm2, pixnum_parietal_wm2] = ROI_from_Parcel(parc_wm, [3005 3008 3022 3025 3029 3031 4005 4008 4022 4025 4029 4031]);
parietal_wm = double(or(parietal_wm1,parietal_wm2));
pixnum_parietal_wm = pixnum_parietal_wm1 + pixnum_parietal_wm2;
clear parietal_wm1 parietal_wm2 pixnum_parietal_wm1 pixnum_parietal_wm2;
gmwm_combined = parietal_gm .* parietal_wm;
if (max(gmwm_combined(:)) ~= 0)
    disp('There is an overlapped region with both WM and GM in parietal. Needed to be checked.')
end
img_nii.img = parietal_gm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'parietal_gm.nii'));
img_nii.img = parietal_wm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'parietal_wm.nii'));

[temporal_lateral_gm, pixnum_temporal_lateral_gm] = ROI_from_Parcel(parc_gm, [1001 2001 1009 1013 1015 1030 1033 2009 2013 2015 2030 2033]);
[temporal_lateral_wm, pixnum_temporal_lateral_wm] = ROI_from_Parcel(parc_wm, [3001 4001 3007 3009 3013 3015 3030 3033 4007 4009 4013 4015 4030 4033]);
gmwm_combined = temporal_lateral_gm .* temporal_lateral_wm;
if (max(gmwm_combined(:)) ~= 0)
    disp('There is an overlapped region with both WM and GM in temporal_lateral. Needed to be checked.')
end
img_nii.img = temporal_lateral_gm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'temporal_lateral_gm.nii'));
img_nii.img = temporal_lateral_wm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'temporal_lateral_wm.nii'));

% [temporal_medial_gm, pixnum_temporal_medial_gm] = ROI_from_Parcel(parc_gm, [17 18 53 54 1006 1010 1016 2006 2010 2016]);
[temporal_medial_gm, pixnum_temporal_medial_gm] = ROI_from_Parcel(parc_gm, [17 18 53 54 1006 1016 2006 2016]);
% [temporal_medial_wm, pixnum_temporal_medial_wm] = ROI_from_Parcel(parc_wm, [3006 3010 3016 4006 4010 4016]);
[temporal_medial_wm, pixnum_temporal_medial_wm] = ROI_from_Parcel(parc_wm, [3006 3016 4006 4016]);
gmwm_combined = temporal_medial_gm .* temporal_medial_wm;
if (max(gmwm_combined(:)) ~= 0)
    disp('There is an overlapped region with both WM and GM in temporal_medial. Needed to be checked.')
end
img_nii.img = temporal_medial_gm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'temporal_medial_gm.nii'));
img_nii.img = temporal_medial_wm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'temporal_medial_wm.nii'));

% posteriorcingulate and isthmuscingulate separated from parietal and temporal_medial, resp.
[PIcing_gm, pixnum_PIcing_gm] = ROI_from_Parcel(parc_gm, [1010 1023 2010 2023]);
[PIcing_wm, pixnum_PIcing_wm] = ROI_from_Parcel(parc_wm, [3010 3023 4010 4023]);
gmwm_combined = PIcing_gm .* PIcing_wm;
if (max(gmwm_combined(:)) ~= 0)
    disp('There is an overlapped region with both WM and GM in PIcing. Needed to be checked.')
end
img_nii.img = PIcing_gm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'PIcing_gm.nii'));
img_nii.img = PIcing_wm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'PIcing_wm.nii'));

[occipital_gm, pixnum_occipital_gm] = ROI_from_Parcel(parc_gm, [1011 1021 2011 2021]);
[occipital_wm, pixnum_occipital_wm] = ROI_from_Parcel(parc_wm, [3011 3021 4011 4021]);
gmwm_combined = occipital_gm .* occipital_wm;
if (max(gmwm_combined(:)) ~= 0)
    disp('There is an overlapped region with both WM and GM in occipital. Needed to be checked.')
end
img_nii.img = occipital_gm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'occipital_gm.nii'));
img_nii.img = occipital_wm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'occipital_wm.nii'));

[abnormal_gm, pixnum_abnormal_gm] = ROI_from_Parcel(parc_gm, [25 57 81 82 101 102 103 104 105 106 107 110 111 112 113 114 115 116]);
[abnormal_wm, pixnum_abnormal_wm] = ROI_from_Parcel(parc_gm, [77 78 79 80 100 109]);
gmwm_combined = abnormal_gm .* abnormal_wm;
if (max(gmwm_combined(:)) ~= 0)
    disp('There is an overlapped region with both WM and GM in abnormal. Needed to be checked.')
end
img_nii.img = abnormal_gm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'abnormal_gm.nii'));
img_nii.img = abnormal_wm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'abnormal_wm.nii'));

% [subcortical_gm, pixnum_subcortical_gm] = ROI_from_Parcel(parc_gm, [9 10 11 12 13 26 48 49 50 51 52 58 1007 2007]);
[subcortical_gm, pixnum_subcortical_gm] = ROI_from_Parcel(parc_gm, [26 58 1007 2007]);
[subcortical_wm, pixnum_subcortical_wm] = ROI_from_Parcel(parc_wm, [5001 5002]);
gmwm_combined = subcortical_gm .* subcortical_wm;
if (max(gmwm_combined(:)) ~= 0)
    disp('There is an overlapped region with both WM and GM in subcortical. Needed to be checked.')
end
img_nii.img = subcortical_gm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'subcortical_gm.nii'));
img_nii.img = subcortical_wm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'subcortical_wm.nii'));

% thalamus and basal ganglia separated from subcortical_gm
[thalamus, pixnum_thalamus] = ROI_from_Parcel(parc_gm, [9 10 48 49]);
[basal_ganglia, pixnum_basal_ganglia] = ROI_from_Parcel(parc_gm, [11 12 13 50 51 52]);
img_nii.img = thalamus;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'thalamus.nii'));
img_nii.img = basal_ganglia;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'basal_ganglia.nii'));

[csf, pixnum_csf] = ROI_from_Parcel(parc_gm, [4 5 14 15 24 43 44 75 76]);
img_nii.img = csf;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'csf.nii'));

[brainstem, pixnum_brainstem] = ROI_from_Parcel(parc_gm, [6 7 8 16 27 45 46 47 59]);
img_nii.img = brainstem;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'brainstem.nii'));

[insula_gm, pixnum_insula_gm] = ROI_from_Parcel(parc_gm, [19 20 55 56 1034 1035 2034 2035]);
[insula_wm, pixnum_insula_wm] = ROI_from_Parcel(parc_wm, [3034 3035 4034 4035]);
gmwm_combined = insula_gm .* insula_wm;
if (max(gmwm_combined(:)) ~= 0)
    disp('There is an overlapped region with both WM and GM in insula. Needed to be checked.')
end
img_nii.img = insula_gm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'insula_gm.nii'));
img_nii.img = insula_wm;
save_untouch_nii(img_nii, strcat(dir_MPRAGE, 'insula_wm.nii'));

