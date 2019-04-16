function resamp_nii = create_t2t2star_resamp(id)
%%  CREATE_DCMS - create t2t2star from raw directoires given id

   % id = '10644_20180216';

   rawpath=fullfile('/Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/',id);
   rawnii_path=fullfile('/Volumes/Hera/Projects/7TBrainMech/subjs',id,'R2prime/raw');
   resampnii_path=fullfile('/Volumes/Hera/Projects/7TBrainMech/subjs',id,'R2prime/raw/3x3x3');

   % check if we already have what we need
   resamp_nii = find_resamp_nii(resampnii_path);
   if ~isempty(resamp_nii), return, end

   % create directories we'll need
   mkdir(fileparts(rawnii_path))
   mkdir(rawnii_path)
   mkdir(resampnii_path)


   % check if we have the start
   if ~exist(rawpath,'dir'), error(rawpath, 'does not exist'); end
   dcmdirs = find_files(rawpath,'t2t2star', 1);
   ndirs = length(dcmdirs);
   if ndirs ~= 3, error('number of t2star ndirs %d != 3 for %s', ndirs, id'), end

   % intermiate stage for raw nii (not resampled)
   havenii = find_files(rawnii_path,'nii.gz$', 0);
   if ~isempty(havenii), error('have some raw niis, delete dir to restart: %s', rawnii_path), end

   %% convert from dcm to nii
   % files like 31_1_gre_t2t2star_0031_gre-t2t2star_176.nii.gz
   for d=dcmdirs'
      [root, pdir] = fileparts(d{1});
      cmd = sprintf('dcm2niix_afni -o %s -f %%s_%%e_%%p_%s %s', rawnii_path, pdir, d{1});
      exitcode = system(cmd);
      if exitcode ~= 0, error('%s failed', cmd), end
   end
   % and find all of what we created
   nii_files = find_files(rawnii_path,'^[0-9]+_[0-9]_gre_t2t2star_.*.nii.gz$', 0);
   nnii=length(nii_files);
   if nnii ~= 12, error('need exactly 12 t2t2star multiecho niis have %d', nnii), end

   %% resample
   for n=nii_files'
      [root, fname] = fileparts(n{1});
      cmd = sprintf('3dresample -dxyz 3 3 3 -inset %s -prefix %s',...
                    n{1}, fullfile(resampnii_path, ['resample_' fname]));

      if system(cmd) ~= 0, error('%s failed', cmd), end
   end

   % find and return list
   resamp_nii = find_resamp_nii(resampnii_path);


end

function  nii_files = find_resamp_nii(niipath)
   nii_files = {};
   niipath=fullfile(niipath);
   if ~exist(niipath,'dir'), return, end
   nii_files = find_files(niipath,'.nii.gz$', 0);
   % check we have exatly 12
   nnii = length(nii_files);
   if nnii ~= 12
      error(['number of resamp nii files %d != 12 in %s', ...
            '(fix: remove directory)'],  nnii, niipath)
   end
end

