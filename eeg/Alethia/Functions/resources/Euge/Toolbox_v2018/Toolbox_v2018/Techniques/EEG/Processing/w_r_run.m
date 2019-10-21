function [EEG, data] = w_r_run(script_file_name, transfer_args_file_name, r_path, EEG, data)
if isfield(data,'r_args')
    r_args = data.r_args;
else
    r_args = {};
end
transfer_args_file_name = fullfile(data.path, transfer_args_file_name);
save(transfer_args_file_name, 'r_args')
command_str = [r_path ' ' fullfile(data.ieeglab_path, 'r_scripts', script_file_name) ' ' transfer_args_file_name];
[status, command_out] = system(command_str);
disp(command_str)
if status == 0
    load(transfer_args_file_name)
    data.r_args = r_args;
    fprintf('Status: %d, command_out: %s', status, command_out);
    display('DONE')
else
    fprintf('Status: %d, command_out: %s', status, command_out);
end