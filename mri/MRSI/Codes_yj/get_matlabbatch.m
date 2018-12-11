function matlabbatch = get_matlabbatch()
% GET_MATLABBATCH return spm coreg settings struct stored in mat file
% loads "SPMcoreg.mat" from directory this function is saved in
   this_script    = mfilename('fullpath');
   [this_dir, ~ ] = fileparts(this_script);
   mat_loc        = fullfile(this_dir, 'SPMcoreg.mat');
   % load with assignment so matlab lint doesn't complain -- no orange here
   m = load(mat_loc,'matlabbatch');
   matlabbatch = m.matlabbatch;
end

% >> load('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/Codes_yj/SPMcoreg.mat','matlabbatch')
% >> matlabbatch{1}.spm.spatial.coreg.estwrite
%          ref: {'/mnt/Partition3/Ajay/UF_RS/CON/CON_017/CON_017.SPGR.nii,1'}
%       source: {'/mnt/Partition3/Ajay/UF_RS/CON/CON_017/CON_017.T2.nii,1'}
%        other: {''}
%     eoptions: [1×1 struct]
%     roptions: [1×1 struct]
% >> matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions
%     cost_fun: 'nmi'
%          sep: [4 2]
%          tol: [0.0200 0.0200 0.0200 1.0000e-03 1.0000e-03 1.0000e-03 0.0100 0.0100 0.0100 1.0000e-03 1.0000e-03 1.0000e-03]
%         fwhm: [7 7]
% 
% >> matlabbatch{1}.spm.spatial.coreg.estwrite.roptions
%   struct with fields:
%     interp: 4
%       wrap: [0 0 0]
%       mask: 0
%     prefix: 'r'