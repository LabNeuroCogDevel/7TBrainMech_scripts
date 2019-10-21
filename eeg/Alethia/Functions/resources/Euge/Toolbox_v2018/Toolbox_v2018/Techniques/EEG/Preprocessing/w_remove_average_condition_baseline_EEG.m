function [ EEG, data ] = w_remove_average_condition_baseline_EEG(path_to_files,epochs,time_range,path_to_save,EEG,data)

data.parent_directory = '';
[data] = w2_remove_average_condition_baseline_EEG(path_to_files,epochs,time_range,path_to_save,data);