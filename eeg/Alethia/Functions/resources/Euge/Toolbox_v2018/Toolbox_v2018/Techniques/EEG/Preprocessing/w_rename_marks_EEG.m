function [EEG, data] = w_rename_marks_EEG(path_to_files,condition_names, condition_marks,path_to_save,EEG,data)

data.parent_directory = '';
data = w2_rename_marks_EEG(path_to_files,condition_names,condition_marks,path_to_save,data);
