function [ EEG, data ] = w_smi_EEG(filepath_to_save, data_range, kernel, taus, EEG, data )
%PREPROC Summary of this function goes here
%   Detailed explanation goes here

%load parameters
if isfield(data,'path_to_files')    
    filepath_to_data = data.path_to_files;
else 
    msgbox('Load path to data');
end;

data_range = str2num(data_range);
kernel = str2num(kernel);
%fs = str2num(fs);
taus = str2num(taus);

%%
% clear all 
% clc
% 
% filepath_to_data = 'D:\Euge\EEG_toolbox_test\datos_ej';
% data_range = [0 1];
% kernel = 3;
% taus = [1 2 4 8 16 32];

%%
listing = dir(filepath_to_data);
dirFlags = [listing.isdir];
filenames = listing(~dirFlags);
file_nr = size(filenames',2);
extFlags = false(1,file_nr);
for f = 1 : size(filenames,1)
    [parts name ext] = fileparts(filenames(f).name);
    if strcmp(ext,'.set')
        extFlags(f) = true;
    end
end
final_filenames = filenames(extFlags);
final_file_nr = size(final_filenames,1);

for suj = 1 : final_file_nr
    file_name = final_filenames(suj).name;
%CREO QUE ESTA FUNCION NO TIENE QUE VER CON LO QUE QUIERO HACER
    %%function [ handles ] = load_file( file_name, path, handles )
    %%SAVE_FILE Summary of this function goes here
    %%   Detailed explanation goes here
%     load(fullfile(filepath_to_data, file_name));
%     [pathstr,~,~] = fileparts(which('ieeglab'));
%     data.ieeglab_path = pathstr;
%     handles.data = data;
    %%end
    disp(filepath_to_data)
    disp(file_name)
    EEG = pop_loadset('filename',file_name,'filepath', filepath_to_data);
    EEG = eeg_checkset( EEG );
    handles.data.EEG = EEG;
    handles.data.set_file_name = file_name;
    handles.data.data_status = 0;
    %load_handles(handles); %ESTO ME FALLA!!!!!!

    selected_epoched_EEG = EEG;
    %NO ENTIENDO PARA QUE ESTA ESTO
%     if isfield(data, 'selected_epoched_EEG')
%         selected_epoched_EEG = data.selected_epoched_EEG;
%     end
    
    fs = EEG.srate;
    start_point = find(abs(selected_epoched_EEG.times - data_range(1)*1000) < 1000/fs);
    end_point = find(abs(selected_epoched_EEG.times - data_range(2)*1000) < 1000/fs);
    if ~start_point
        start_point = 1;
    end
    if ~end_point
        end_point = length(selected_epoched_EEG.times);
    end
    disp(start_point(1))
    disp(end_point(1))
    point_range = start_point(1):end_point(1);
    
    [file_path filename_to_save file_ext] = fileparts(file_name);

    [sym ,~ ] = symbolic_transfer(selected_epoched_EEG.data,kernel, fs, taus, point_range,data.path_to_save,filename_to_save);

    mutual_information(data.path_to_save, filename_to_save, sym, taus);
    disp('done suj')
end
return