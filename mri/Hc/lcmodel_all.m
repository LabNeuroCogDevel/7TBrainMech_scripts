% see 03_lcmodel_all.bash
% run like: matlab -nodisplay -nojvm -r "try, run('lcmodel_all.m'), end; quit()"
addpath('/Volumes/Hera/Raw/MRprojects/7TBrainMech/CSIProcessing/lcmodel')
files=dir('spectrum/2*/spectrum.*');
files = files(~[files.isdir]);
fprintf('# %d spec files in spectrum/2*/spectrum*\n', length(files))
for f=files'
   if contains(f.name,'siblock'), continue, end
   spec=fullfile(f.folder,f.name);
   disp(spec)
   lcmodel_spec(spec)
end
