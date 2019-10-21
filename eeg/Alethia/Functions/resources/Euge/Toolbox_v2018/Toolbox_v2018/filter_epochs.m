function result_EEG = filter_epochs(epochs, data)
if(~isfield(data,'EEG'))
    if(isfield(data,'path_to_files'))
        files = dir(fullfile(data.path_to_files,'*.set'));
        filenames = {files.name}';  
        [selection,ok]=listdlg('ListString',filenames,'Name','Select file');
            if(ok)
                EEG = pop_loadset('filename',filenames{selection},'filepath', data.path_to_files);
                EEG = eeg_checkset( EEG );
                data.EEG=EEG;
            else
                msgbox('No file was selected');
                return;
            end
    else
        [file_name, file_path] = uigetfile('*','Select .set file');
        data.data_file_name=file_name;
        if(file_name)
            EEG = pop_loadset('filename',file_name,'filepath', file_path);
            EEG = eeg_checkset( EEG );
            data.EEG = EEG;
        else
         msgbox('No file has been selected');
         return;
        end
    end
else
    EEG=data.EEG;
end
results = calculate_epochs_mask(epochs, EEG);
EEG.data = EEG.data(:,:,results);
EEG.epoch = EEG.epoch(results);
result_EEG = EEG;
