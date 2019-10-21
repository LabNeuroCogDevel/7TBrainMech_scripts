function [EEG, data] = w_python_run(script_file_name, transfer_set_file_name, transfer_args_file_name, python_path, EEG, data)
if isequal(python_path,'')
    python_path = 'python';
end
if isfield(data,'python_args')
    python_args = data.python_args;
else
    python_args = {};
end
transfer_args_file_name = fullfile(data.path, transfer_args_file_name);
original_names = unique({EEG.event.type});
new_names = strsplit(num2str(1:length(original_names)));
EEG = change_events_name(original_names, new_names, EEG);
EEG = pop_saveset( EEG, 'filepath', data.path, 'filename', transfer_set_file_name);
save(transfer_args_file_name, 'python_args')
command_str = [python_path ' ' fullfile(data.ieeglab_path, 'python_scripts', script_file_name) ' ' fullfile(data.path,transfer_set_file_name) ' ' transfer_args_file_name];
[status, command_out] = system(command_str);
disp(command_str)
if status == 0
    load(transfer_args_file_name)
    data.python_args = python_args;
    fprintf('Status: %d, command_out: %s', status, command_out);
    EEG = pop_loadset('filepath', data.path, 'filename', transfer_set_file_name);
    display('DONE')
else
    fprintf('Status: %d, command_out: %s', status, command_out);
end
EEG = change_events_name(new_names, original_names, EEG);