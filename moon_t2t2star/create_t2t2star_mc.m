function t2t2s_out = create_t2t2star_mc(id)
%%  CREATE_DCMS - create t2t2star from raw directoires given id

   % we will decend into subject directoires
   scriptd=pwd();
   addpath(scriptd);

   % id = '10644_20180216';

   rawpath=fullfile('/Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/',id);
   rawnii_path=fullfile('/Volumes/Hera/Projects/7TBrainMech/subjs',id,'R2prime/raw');
   mc_path=fullfile('/Volumes/Hera/Projects/7TBrainMech/subjs',id,'R2prime/mc');

   % check if we already have what we need
   t2t2s_out = find_mc_files(mc_path);
   if ~isempty(t2t2s_out), return, end

   % create directories we'll need
   for d={fileparts(rawnii_path),rawnii_path, mc_path}
      if ~exist(d{1}, 'dir'), mkdir(d{1}); end
   end

   % check if we have the start
   if ~exist(rawpath,'dir'), error(rawpath, 'does not exist'); end
   dcmdirs = find_files(rawpath,'t2t2star', 1);
   ndirs = length(dcmdirs);
   if ndirs ~= 3
      error('number of t2star ndirs %d != 3 for %s;%s:\n\t%s',...
            ndirs, id', rawpath, strjoin(dcmdirs,'\n\t'))
   end

   % intermiate stage for raw nii (not resampled)
   havenii = find_files(rawnii_path,'nii.gz$', 0);
   if isempty(havenii)
      %% convert from dcm to nii
      % files like 31_1_gre_t2t2star_0031_gre-t2t2star_176.nii.gz
      disp(' * dcm2nii')
      for d=dcmdirs'
         [root, pdir] = fileparts(d{1});
         cmd = sprintf('dcm2niix_afni -o %s -f %%s_%%e_%%p_%s %s', rawnii_path, pdir, d{1});
         exitcode = system(cmd);
         if exitcode ~= 0, error('%s failed', cmd), end
      end
   elseif length(havenii) ~= 12
      error('have some raw niis but not all, delete dir to restart: %s', rawnii_path)
   end

   % and find all of what we created
   nii_files = find_files(rawnii_path,'^[0-9]+_[0-9]_gre_t2t2star_.*.nii.gz$', 0);
   nnii=length(nii_files);
   if nnii ~= 12
      error('need exactly 12 t2t2star multiecho niis have %d', nnii)
   end


   % check mprage files exist
   mprage_bet = fullfile(mc_path,'../../preproc/t1/mprage_bet.nii.gz');
   if ~exist(mprage_bet, 'file')
      error(['missing mpage bet! (%s);' ...
            'consider "pp  7TBrainMech_rest MHRest_nost_ica %s"'], ...
            mprage_bet, id)
   end
   %% make ts of files, motion correct, resample
   cd(mc_path)
   disp(pwd)
   disp(' * first pass motion correction and linear warp')
   system(['3dTcat -prefix t2t2star_ts.nii.gz ', strjoin(nii_files, ' ')]);
   run_ni('mcflirt -in t2t2star_ts.nii.gz -out mc -refvol 0 -mats', 1);
   run_ni('bet mc mc_bet -R');
   run_ni(sprintf('flirt -in mc_bet -ref %s  -omat t2_mprage.mat -o t2_mprage.nii.gz -dof 6 -interp spline', mprage_bet));
   % run_ni('3dresample -dxyz 3 3 3 -inset mc.nii -prefix mc_3mm.nii', 1)
   cd(scriptd);


   % find and return list
   t2t2s_out = find_mc_files(mc_path);

end

function  out = find_mc_files(niipath)
   out = [];
   niipath=fullfile(niipath);
   if ~exist(niipath,'dir'), return, end
   mc = find_files(niipath,'mc.nii$', 0);
   % check we have exatly 12
   nnii = length(mc);
   if nnii ~= 1
      error(['number of resamp nii files %d != 1 in %s', ...
            '(fix: remove directory)'],  nnii, niipath)
   end
   
   warp_mat = find_files(niipath,'t2_mprage.mat$');
   if isempty(warp_mat)
      error('failed to create warp file %s, consider rm dir to try again',...
            fullfile(niipath,'t2_mprage.mat'))
   end

   out.mc = mc{1};
   out.warp_mat = warp_mat{1};
   out.basedir = fileparts(niipath);
end
