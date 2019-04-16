function files = files_files(searchpath, pattern, wantdir)
   %% find files in searchpath matching pattern and are or arenot a directory
   files={};
   if ~exist(searchpath,'dir'), return, end
   if nargin <=2, wantdir = 0; end
   all_files = dir(searchpath);
   idx = cellfun(@length,regexp({all_files.name},pattern) )  & ...
         [all_files.isdir]== wantdir;
   files = arrayfun(@(x) fullfile(x.folder, x.name), all_files(idx), 'Un', 0);
end
