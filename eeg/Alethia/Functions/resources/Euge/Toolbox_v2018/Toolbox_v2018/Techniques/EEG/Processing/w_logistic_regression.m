function [EEG, data] = w_logistic_regression(table_filename, label_filename, binary_column_name, binary_column, initial_column_data, alpha, path_to_save, perform_save, transfer_args_file_name, r_path, EEG, data)
data.r_args.table_filename = fullfile(data.path, table_filename);%'P9_RegTable.mat';
data.r_args.label_filename = fullfile(data.path, label_filename);%'P9_RegTable_labels.mat';

data.r_args.binary_column_name = binary_column_name;%'Stymulus.Type'
data.r_args.binary_column = str2num(binary_column);%5
data.r_args.initial_column_data = str2num(initial_column_data);%10

data.r_args.alpha = str2num(alpha);%0.05
data.r_args.path_to_save = fullfile(data.path, path_to_save);%'testprint\\';

data.r_args.save = str2num(perform_save);%1

[EEG, data] = w_r_run('R_logistic_regression.R', transfer_args_file_name, r_path, EEG, data);