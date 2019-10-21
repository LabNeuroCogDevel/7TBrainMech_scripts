function [EEG, data] = w_brief_time_span_connectivity(condition_1, condition_2,bandpassRange,epoch_window,base_window,method,path_to_save,newFileName,EEG,data)
addpath(fullfile(data.ieeglab_path,'epoching'));
if isequal(path_to_save,'')
    path_to_save = fullfile(data.path, 'BTS');
end
if ~exist(path_to_save, 'dir')
  mkdir(path_to_save);
end

%EEG without epoching, for future filtering
preprocessed_EEG = data.preprocessed_data;

bandpassRange = str2num(bandpassRange);%[0 150];
epoch_window = str2num(epoch_window);%[-250 1000];
base_window = str2num(base_window);%[-250 0];
newFileName = fullfile(path_to_save, newFileName);

calculate_brief_time_span(preprocessed_EEG,condition_1, condition_2,bandpassRange,epoch_window,base_window,method,newFileName);