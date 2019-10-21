function [ data ] = w2_remove_average_condition_baseline_EEG(path_to_files,epochs,time_range,path_to_save,data )
%-------DESCRIPTION---------------
%Every set in the specified directory is loaded and then the baselines of 
%the epochs indicated (if none provided all epochs are considered) 
%are averaged and then substracted from the baseline of each trial. 
%This procedure is performed by channel. 
%The new sets are saved in the path provided.
%INPUTS: 
%   * path_to_files: the sets' directory.
%   * epochs: the marks of the desired epochs. The sets will be filtered by
%       to contain only the indicated marks/epochs.
%   * time_range: a vector of 2 values, indicating the initial and final
%       times of the considered baseline. The time range
%       must be contained within the original epoch time frame. 
%       Must be set in miliseconds.
%   * path_to_save: the directory where the new sets will be saved with
%       the same name as the ones found in the path_to_files directory.
%OUTPUTS:
%   * the average condition baseline sets stored in path_to_save.
%----------------------------------

%-------PATH MANAGEMENT-----------
%----------------------------------
%add path of preprocessing 
addpath(fullfile(data.ieeglab_path,'preprocessing'));
addpath(fullfile(data.ieeglab_path,'processing'));

%modifies paths to include parent directory
path_to_files = fullfile(data.parent_directory, path_to_files);
path_to_save = fullfile(data.parent_directory, path_to_save);

% %check if path to files exist
assert(exist(path_to_files, 'dir') == 7,['Directory not found! path_to_files: ' path_to_files '.']);

%create directory where the average condition baseline sets will be stored
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
    %select epochs
    if ~isempty(epochs)
        epochs = strsplit(epochs);        
        EEG = pop_selectevent( EEG, 'type', epochs ,'deleteevents','off','deleteepochs','on','invertepochs','off');
    end
    %average condition baseline
    EEG = remove_average_condition_baseline(EEG,time_range); 
    %check EEG's consistency
    EEG = eeg_checkset( EEG );
    %save set
    EEG = pop_saveset( EEG, 'filename',file_name,'filepath',path_to_save);
end

