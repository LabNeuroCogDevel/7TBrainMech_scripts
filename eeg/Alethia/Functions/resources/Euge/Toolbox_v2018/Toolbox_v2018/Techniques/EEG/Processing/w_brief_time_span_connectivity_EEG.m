function [EEG, data] = w_brief_time_span_connectivity_EEG(condition_1, condition_2,bandpass_ranges,epoch_window,base_window,time_ranges,path_to_save,newFileName,EEG,data)

%-------PATH MANAGEMENT-----------
%----------------------------------

%add path of epoching 
addpath(fullfile(data.ieeglab_path,'epoching'));

%TODO create new directories for results? 
%creates this path to separate statistical results from matrix calculation
if isequal(path_to_save,'')
    path_to_save_mats = fullfile(data.path, 'BTS');
end

if ~exist(path_to_save_mats, 'dir')
  mkdir(path_to_save_mats);
end

%-------LOAD PARAMETERS------------
%----------------------------------

bandpass_ranges = str2num(bandpass_ranges);
epoch_window = str2num(epoch_window);
base_window = str2num(base_window);
time_ranges = str2num(time_ranges);

%hace falta??
newFileName = fullfile(path_to_save, newFileName);

%---------RUN---------------------
%---------------------------------

%load .set for every subject without epoching, for future filtering

path_to_files=data.path_to_files{1};

files = dir(fullfile(path_to_files,'*.set'));
filenames = {files.name}';  
file_nr = size(filenames,1);

%Calculates brief time span matrices for each condition for every frequency
%and time range. Saves results in subfolder 'path_to_save\BTS'.
for suj = 1 : file_nr
    file_name = filenames(suj).name;
    disp(filepath_to_data)
    disp(file_name)
    EEG = pop_loadset('filename',file_name,'filepath', filepath_to_data);
    EEG = eeg_checkset( EEG );
    handles.data.EEG = EEG;
    handles.data.set_file_name = file_name;
    handles.data.data_status = 0;
    %load_handles(handles); %ESTO ME FALLA!!!!!!

    preprocessed_EEG = EEG;
    calculate_brief_time_span(preprocessed_EEG,condition_1, condition_2,bandpass_ranges,epoch_window,base_window,time_ranges,path_to_save_mats);
end

%Calculate statistical comparisons