% run fsl or afni command maybe w/ settings to make .nii
function [s, o] = run_ni(cmd, nii_only)
   if nargin >= 2 && nii_only == 1
      cmd = ['FSLOUTPUTTYPE="NIFTI" ' cmd];
      cmd = ['AFNI_COMPRESSOR="" ' cmd];
   end
   lib = 'LD_LIBRARY_PATH="/usr/lib/fsl/5.0" ';
   [s, o] = system([lib cmd]);
end
