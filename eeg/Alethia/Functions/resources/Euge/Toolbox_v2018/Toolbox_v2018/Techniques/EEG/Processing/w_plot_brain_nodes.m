function [EEG, data] = w_plot_brain_nodes( node_file_name, brain_file_path, configuration_mat,filename_to_save, EEG, data)
%plots the brain nodes (electrode sites) using Brain Net Viewer. Requires the node file, and the
%relative path where the brain template is, and an optional parameter of the
%configuration mat (relative path + filename)

surfaceFile = fullfile(data.path, brain_file_path,'BrainMesh_ICBM152.nv');

if ~isequal(configuration_mat,'')
    configuration_mat = fullfile(data.path, configuration_mat);
end
   
BrainNet_MapCfg(surfaceFile,node_file_name,configuration_mat,filename_to_save);

display('END: w_plot_brain_nodes')

