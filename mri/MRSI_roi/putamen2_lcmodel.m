%#!/opt/ni_tools/lncdtools/ml 
addpath('/Volumes/Hera/Raw/MRprojects/7TBrainMech/CSIProcessing/lcmodel')
spec_glob = '../../../subjs/1*/slice_PFC/MRSI_roi/putamen2/*/spectrum.*';
files=dir(spec_glob);
files = files(~[files.isdir]);
fprintf('# %d spec files in "%s"\n', length(files), spec_glob)
for f=files'
   if contains(f.name,'siblock'), continue, end
   spec=fullfile(f.folder,f.name);
   disp(spec)
   lcmodel_spec(spec)
end

