function EEG = load_if_exists(infile)
   if exist(infile, 'file')
      fprintf('** have %s, loading it up!\n', infile);
      EEG = pop_loadset(infile);
   else
      EEG = 0
   end
end

