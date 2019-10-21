function [EEG,data] = w_remove_epochs_EEG(path_to_allepochs,path_to_preprocessed_files,epochs_to_remove, path_to_save,EEG,data)
                                         
data.parent_directory = '';
[data] = w2_remove_epochs_EEG(path_to_allepochs,path_to_preprocessed_files,epochs_to_remove, path_to_save,data);