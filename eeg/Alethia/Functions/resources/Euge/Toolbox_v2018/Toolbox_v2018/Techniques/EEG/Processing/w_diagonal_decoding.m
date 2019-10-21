function [EEG, data] = w_diagonal_decoding(picked_channels, event_0, event_1, fold_nr, outputfile, semfactor, transfer_set_file_name, transfer_args_file_name, python_path, EEG, data)
data.python_args.set_path = fullfile(data.path, transfer_set_file_name);
data.python_args.picked_channels = str2num(picked_channels);%[];
data.python_args.event_1 = str2num(event_1);%[1];
data.python_args.event_0 = str2num(event_0);%[2];
data.python_args.fold_nr = str2num(fold_nr);%3;
data.python_args.outputfile = fullfile(data.path, outputfile);%'decoding_test'
data.python_args.semfactor = str2num(semfactor);%1.98;

[EEG, data] = w_python_run('diagonal_decoding.py', transfer_set_file_name, transfer_args_file_name, python_path, EEG, data);