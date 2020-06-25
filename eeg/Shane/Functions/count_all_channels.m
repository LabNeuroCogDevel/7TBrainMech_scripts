function [fls, n] = count_all_channels(pattern)
   if nargin < 1 || isempty(pattern)
      % pattern= '/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Alethia/Prep/remarked/1*_2*_*_Rem.set'
      % pattern='/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/epochclean/1*_2*_*_Rem_rerefwhole_ICA_icapru_epochs_rj.set';
      % see if interpolating fixed it
      pattern='/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Alethia/Prep/*/1*_2*_*Rem_rerefwhole.set';
   end
   fls = dir(pattern);
   n = zeros(1,length(fls));
   for i = 1:length(fls)
      e = pop_loadset(fls(i).name, fls(i).folder);
      n(i) = length(e.chanlocs);
      disp(n(i));
   end
end

