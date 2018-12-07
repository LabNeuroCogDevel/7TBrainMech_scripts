function spm_registration_ROI_ft_plusExtras(matlabcode_dir,ROI_dir,data_dir,filename_scout,flair_flag,filename_flair)

% clear all
% matlabcode_dir = '/Users/yoojin/Desktop/MRResearch/MRData/MRSI/Script';
% ROI_dir = '/Users/yoojin/Desktop/MRResearch/MRData/MRSI/Luna_Schizo/tmp/parc_group';
% data_dir = '/Users/yoojin/Desktop/MRResearch/MRData/MRSI/Luna_Schizo/tmp';
% filename_scout = '31slicesB0mappingScouts004a1001.nii';
% flair_flag = 1;
% filename_flair = 'AXIALFLAIRs008a1001.nii';

%% Coregister MPRAGE to resized Scout (trilinear)
pos = findstr(filename_scout,'.');
% load premade matlabbatch{1}.spm.spatial.coreg.estwrite
load(strcat(matlabcode_dir, filesep,'/SPMcoreg.mat'));
matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {[strcat(data_dir,filesep,filename_scout(1:(pos-1)),'_resize.nii,1')]}';
matlabbatch{1}.spm.spatial.coreg.estwrite.source = {[strcat(ROI_dir,filesep,'orig.nii,1')]}';
matlabbatch{1}.spm.spatial.coreg.estwrite.other = {[strcat(ROI_dir,filesep,'abnormal_gm.nii,1')],[strcat(ROI_dir,filesep,'abnormal_wm.nii,1')],[strcat(ROI_dir,filesep,'brainstem.nii,1')],[strcat(ROI_dir,filesep,'csf.nii,1')],[strcat(ROI_dir,filesep,'frontal_gm.nii,1')],[strcat(ROI_dir,filesep,'frontal_wm.nii,1')],[strcat(ROI_dir,filesep,'insula_gm.nii,1')],[strcat(ROI_dir,filesep,'insula_wm.nii,1')],[strcat(ROI_dir,filesep,'occipital_gm.nii,1')],[strcat(ROI_dir,filesep,'occipital_wm.nii,1')],[strcat(ROI_dir,filesep,'parietal_gm.nii,1')],[strcat(ROI_dir,filesep,'parietal_wm.nii,1')],[strcat(ROI_dir,filesep,'subcortical_gm.nii,1')],[strcat(ROI_dir,filesep,'subcortical_wm.nii,1')],[strcat(ROI_dir,filesep,'temporal_lateral_gm.nii,1')],[strcat(ROI_dir,filesep,'temporal_lateral_wm.nii,1')],[strcat(ROI_dir,filesep,'temporal_medial_gm.nii,1')],[strcat(ROI_dir,filesep,'temporal_medial_wm.nii,1')],[strcat(ROI_dir,filesep,'CAcing_gm.nii,1')],[strcat(ROI_dir,filesep,'CAcing_wm.nii,1')],[strcat(ROI_dir,filesep,'RAcing_gm.nii,1')],[strcat(ROI_dir,filesep,'RAcing_wm.nii,1')],[strcat(ROI_dir,filesep,'PIcing_gm.nii,1')],[strcat(ROI_dir,filesep,'PIcing_wm.nii,1')],[strcat(ROI_dir,filesep,'thalamus.nii,1')],[strcat(ROI_dir,filesep,'basal_ganglia.nii,1')]}';
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 0;
% matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [1 1 1];

spm fmri
spm_jobman('run',matlabbatch);
clear matlabbatch;

%% Coregister MPRAGE to resized Scout (4th degree)
load(strcat(matlabcode_dir, filesep,'/SPMcoreg.mat'));
matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {[strcat(data_dir,filesep,filename_scout(1:(pos-1)),'_resize.nii,1')]}';
matlabbatch{1}.spm.spatial.coreg.estwrite.source = {[strcat(ROI_dir,filesep,'orig.nii,1')]}';
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
% matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [1 1 1];

spm_jobman('run',matlabbatch);
clear matlabbatch;


%% Coregister FLAIR to resized Scout
if (flair_flag == 1)
    load(strcat(matlabcode_dir, filesep,'/SPMcoreg.mat'));
    matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {[strcat(data_dir,filesep,filename_scout(1:(pos-1)),'_resize.nii,1')]}';
    matlabbatch{1}.spm.spatial.coreg.estwrite.source = {[strcat(data_dir,filesep,filename_flair,',1')]}';
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
%     matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [1 1 2];
    
%     spm fmri
    spm_jobman('run',matlabbatch);
end

close all;
