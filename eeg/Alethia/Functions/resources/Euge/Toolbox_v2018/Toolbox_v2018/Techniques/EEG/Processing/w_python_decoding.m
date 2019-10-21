function [EEG, data] = w_python_decoding(script_file_name, transfer_file_name, param_test, python_path, EEG, data)
if isequal(python_path,'')
    python_path = 'python';
end
EEG = pop_saveset( EEG, 'filename', transfer_file_name,'filepath',data.path);
command_str = [python_path ' ' fullfile('python_scripts', script_file_name) ' ' transfer_file_name ' ' param_test];
[status, command_out] = system(command_str);
if status == 0
    load(transfer_file_name)
    EEG.data = eeg_data;
    display('DONE')
else
    fprintf('Status: %d, command_out: %s', status, command_out);
end