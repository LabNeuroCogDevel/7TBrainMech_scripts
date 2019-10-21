function [ data ] = w2_temporal_trim_epochs_EEG(path_to_files,time_range, path_to_save,data )
%-------DESCRIPTION---------------
%Every set in the specified directory is loaded and then trimmed 
%to the indicated time range. After the set is trimmed it is saved in the
%new path with the same name.
%INPUTS: 
%   * path_to_files: the sets' directory.
%   * time_range: a vector of 2 values, indicating the initial and final
%       times of the desired epochs. The rest will be trimmed. The time range
%       must be contained within the original epoch time frame. Must be set
%       in miliseconds.
%   * path_to_save: the relative directory where the trimmed sets will be saved with
%       the same name as the ones found in the path_to_files directory.
%OUTPUTS:
%   * the trimmed sets stored in path_to_save.
%----------------------------------

%-------PATH MANAGEMENT-----------
%----------------------------------
%add path of preprocessing 
addpath(fullfile(data.ieeglab_path,'preprocessing'));

%modifies paths to include parent directory
path_to_files = fullfile(data.parent_directory, path_to_files);
path_to_save = fullfile(data.parent_directory, path_to_save);

%check if path to files exist
if ~exist(path_to_files, 'dir')
    msg = ['Directory not found! path_to_files: ' path_to_files '.'];
    error(msg) 
end

%create directory where the trimmed sets will be stored
if ~exist(path_to_save, 'dir')
  mkdir(path_to_save);
end

%-------LOAD PARAMETERS------------
%----------------------------------
time_range = str2num(time_range);

%---------RUN---------------------
%---------------------------------

%load .set 
files = dir(fullfile(path_to_files,'*.set'));
filenames = {files.name}';  
file_nr = size(filenames,1);

for suj = 1 : file_nr
    file_name = filenames{suj};
    disp(path_to_files)
    disp(file_name)
    %load set
    EEG = pop_loadset('filename',file_name,'filepath', path_to_files);
    %trim EEG
    EEG = temporal_trim(EEG,time_range); 
    %check EEG's consistency
    EEG = eeg_checkset( EEG );
    %save set
    EEG = pop_saveset( EEG, 'filename',file_name,'filepath',path_to_save);
end
