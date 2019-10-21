function [data] = w2_remove_epochs_EEG(path_to_allepochs,path_to_preprocessed_files,epochs_to_remove, path_to_save,data)
%-------DESCRIPTION---------------
%Sets with the same name in the directory where sets that contain all
%epochs and in the directory of preprocessed sets (where epochs have been
%removed) are loaded. ONLY SETS IN BOTH DIRECTORIES ARE LOADED.
%Epochs of both sets are compared to determine which were removed during
%preprocessing. If a struct with the trials to remove as a result of
%conductual analyses is given, if these haven't been removed in the
%preprocessed sets they are removed and saved in the specified directory.
%Files are created were the rejected epochs are registered.
%IMPORTANT: set names must contain a number coherent with the index in the
%struct where the trials to remove are indicated and its suffix must be
%'_SXX' where XX is an integer indicating subject number.
%INPUTS: 
%   * path_to_allepochs: the directory where the sets with all epochs are stored.
%   * path_to_preprocessed_files: the directory where the preprocessed sets
%       are stored.
%   * epochs_to_remove: filename of struct named rejected_trials of the trials to removed. The index of the
%       struct must match the subject number in the filename. 
%   * path_to_save: the directory where the trimmed sets will be saved with
%       the same name as the ones found in the path_to_files directory.
%OUTPUTS:
%   * the sets with the removed trials are stored in path_to_save.
%   * two files will be saved: 1) preprocessed_rejected_trials.txt contains a list by file with the
%       trials removed after preprocessing; 2) total_rejected_trials.txt
%       contains a list by file with trials removed after conductual
%       analysis (and preprocessing). If struct is not provided only file 1
%       will be created.
%----------------------------------

%-------PATH MANAGEMENT-----------
%----------------------------------
%add path of preprocessing 
addpath(fullfile(data.ieeglab_path,'preprocessing'));

%modifies paths to include parent directory
path_to_allepochs = fullfile(data.parent_directory, path_to_allepochs);
path_to_preprocessed_files = fullfile(data.parent_directory, path_to_preprocessed_files);
path_to_save = fullfile(data.parent_directory,path_to_save);

%check if path to files exist
% if exist(path_to_allepochs, 'dir') ~= 7
%     msg = ['Directory not found! path_to_allepochs: ' path_to_allepochs '.'];
%     error(msg) 
% end
assert(exist(path_to_allepochs, 'dir') == 7,['Directory not found! path_to_allepochs: ' path_to_allepochs '.']);

% if exist(path_to_preprocessed_files, 'dir') ~= 7
%     msg = ['Directory not found! path_to_preprocessed_files: ' path_to_preprocessed_files '.'];
%     error(msg) 
% end
assert(exist(path_to_preprocessed_files, 'dir') == 7,['Directory not found! path_to_preprocessed_files: ' path_to_preprocessed_files '.']);

%create directory where the trimmed sets will be stored
if ~exist(path_to_save, 'dir')
  mkdir(path_to_save);
end

%-------LOAD PARAMETERS------------
%----------------------------------
%loads to the workspace a rejected_trials struct
if ~isempty(epochs_to_remove)
    load(epochs_to_remove)
else
    rejected_trials = [];
end

%---------RUN---------------------
%---------------------------------
%FILES
o_all_epochs_files = dir(fullfile(path_to_allepochs, '*.set'));
all_epochs_files = {o_all_epochs_files.name}; % another way to do this %all_epochs_files = extractfield(o_all_epochs_files,'name');
o_rej_epochs_files = dir(fullfile(path_to_preprocessed_files, '*.set'));
rej_epochs_files = {o_rej_epochs_files.name}; % another way to do this %rej_epochs_files = extractfield(o_rej_epochs_files,'name');

%files that have all_epochs and rej_epochs sets ONLY
files = intersect(all_epochs_files,rej_epochs_files);

%load .set 
file_nr = length(files);

%check that struct size is the same as the number of files
if ~isempty(epochs_to_remove)
    if length(files) ~= length(rejected_trials) 
        disp('WARNING - reject_trials struct is of different size than the files that will be processed.')
    end
end

fileID = fopen(fullfile(path_to_save,'preprocessed_rejected_trials.txt'),'w');
fprintf(fileID, '%s\t %s\t %s\t %s\n', 'Sujeto', 'NrTrials', 'NrTrialsEliminados','RejectedTrials');
if ~isempty(epochs_to_remove)
    fid = fopen(fullfile(path_to_save,'total_rejected_trials.txt'),'w');
    fprintf(fid, '%s\t %s\t %s\t %s\n', 'Sujeto', 'NrTrials', 'NrTrialsEliminados','RejectedTrials');
end

for suj = 1 : file_nr
    file_name = files{suj};    
    %get events from all_epochs
    EEG = pop_loadset('filename',file_name,'filepath',path_to_allepochs);
    all_urevent = extractfield(EEG.event,'urevent');
    all_epoch = extractfield(EEG.event,'epoch');

    %get events from rej_epochs
    EEG = pop_loadset('filename',file_name,'filepath',path_to_preprocessed_files);
    rej_urevent = extractfield(EEG.event,'urevent');
    rej_epoch = extractfield(EEG.event, 'epoch');
    nr_trials = EEG.trials;

    %get eliminated epochs
    eliminated_urevents = setdiff(all_urevent,rej_urevent);
    eliminated_epochs = all_epoch(ismember(all_urevent,eliminated_urevents));
    eliminated_epochs_nr = unique(eliminated_epochs);
    str_eliminated_epochs_nr = strjoin(arrayfun(@(x) num2str(x),eliminated_epochs_nr,'UniformOutput',false),',');

    if ~isempty(epochs_to_remove)
        %print info to file
        fprintf(fileID, '%s\t %d\t %d\t %s\n', file_name, nr_trials, length(eliminated_epochs_nr), str_eliminated_epochs_nr);

        %check if rejected include or not trials that should be removed as a
        %result of the conductual analysis    
        %get subject nr
        sep_s = strsplit(file_name,'_'); %splits filename by '_'. Last item must be in the format SNN.set, where NN is subject number
        suj_nr = str2num(sep_s{end}(2:end-4)); %to retrieve subject number the first ('S') and last 4 positions are discarded ('.set')             
        trials_to_remove = setdiff(rejected_trials(suj_nr).trials,eliminated_epochs_nr);
        if ~isempty(trials_to_remove)
            %determine new epoch nr according to those removed from
            %all_epochs - this is because after preprocessing epoch numbers
            %change, and hence using urevents we find the corresponding
            %epoch number of the preprocessed sets, since they don't
            %necessarily have to match.
            rej_epochs_trial_nr = cell2mat(arrayfun(@(x) rej_epoch(find(rej_urevent == all_urevent(find(all_epoch == x,1,'first')))),trials_to_remove,'UniformOutput',false));
            EEG = pop_rejepoch( EEG, rej_epochs_trial_nr ,0);
        end

        %print total info to file
        total_removed_trials = sort([trials_to_remove' eliminated_epochs_nr]); 
        new_str_eliminated_epochs_nr = strjoin(arrayfun(@(x) num2str(x),total_removed_trials,'UniformOutput',false),',');
        fprintf(fid, '%s\t %d\t %d\t %s\n', file_name, length(EEG.epoch), length(eliminated_epochs_nr)+length(trials_to_remove), new_str_eliminated_epochs_nr);            
    end 
    %save set
    pop_saveset( EEG, 'filename',file_name,'filepath',path_to_save);
end

fclose(fileID);
fclose(fid);

