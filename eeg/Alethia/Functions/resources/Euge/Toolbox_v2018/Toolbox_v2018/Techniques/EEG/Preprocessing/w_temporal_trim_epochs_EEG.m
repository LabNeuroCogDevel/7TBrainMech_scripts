function [EEG,data] = w_temporal_trim_epochs_EEG(file_path,time_range,path_to_save,EEG,data)

data.parent_directory = '';
[ data ] = w2_temporal_trim_epochs_EEG(file_path,time_range, path_to_save,data );