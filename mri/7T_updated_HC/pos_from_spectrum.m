function [info] = pos_from_spectrum(spectrum_dir)


   oFd = fopen(fullfile(spectrum_dir,'orient.txt'), 'r');
   % Read the file line by line and extract the numbers
   info.vert = fscanf(oFd, '%*s %d', 1);
   info.horz = fscanf(oFd, '%*s %d', 1);
   info.angle = fscanf(oFd, '%*s %d', 1);

   fclose(oFd);

   %%% 
   % could've just used a for loop
   specfiles = dir(fullfile(spectrum_dir, 'spectrum.*.*'));
   pos = regexp({specfiles.name}, '\.(\d+)\.(\d+)$', 'tokens');
   i = ~ cellfun(@isempty, pos);

   % regexp returns nest cells that are strings
   extracted = cellfun(@(x) cellfun(@str2num,x{1}), ...
                       pos(1,i)','Uni',0);
   info.pos = cell2mat(extracted);
                       
   
end
