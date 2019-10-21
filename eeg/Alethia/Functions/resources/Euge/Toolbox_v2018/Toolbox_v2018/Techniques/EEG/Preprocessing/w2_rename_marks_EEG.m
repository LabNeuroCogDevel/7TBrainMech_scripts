function [data] = w2_rename_marks_EEG(path_to_files,condition_names, condition_marks,path_to_save,data)
%-------DESCRIPTION---------------
%Every set in the specified directory is loaded and the events marked as 
%specified in condition_marks are renamed as condition_name.
%More than one epoch type (mark) can be listed and replaced by one same
%string. The new sets are saved in the specified path.
%IMPORANT: condition names should be separated by commas (e.g. cond1,cond2)
%and condition mark groups should be separated by commas and marks
%belonging to a same condition should be separated by spaces (e.g.
%cond11 cond12 cond13, cond21 cond22).
%INPUTS: 
%   * path_to_files: the sets' directory. 
%   * condition_names: a list of strings that represent the condition names
%           that will replace the marks. Condition names should be
%           separated by commas.
%   * condition_marks: marks that will replaced by condition names. Groups
%           of marks should be separated by commas, and marks within groups
%           by spaces.
%   * path_to_save: the directory where the plots and .mat with results are
%                   stored.
%OUTPUTS:
%   * sets with the renamed marks are saved in the indicated path.
%----------------------------------

%-------PATH MANAGEMENT-----------
%----------------------------------
%add path of preprocessing 
addpath(genpath(fullfile(data.ieeglab_path,'preprocessing')));

%modifies paths to include parent directory
path_to_files = fullfile(data.parent_directory, path_to_files);
path_to_save = fullfile(data.parent_directory, path_to_save);

%check if path to files exist
assert(exist(path_to_files, 'dir') == 7,['Directory not found! path_to_files: ' path_to_files '.']);

%create directory where the trimmed sets will be stored
if ~exist(path_to_save, 'dir')
  mkdir(path_to_save);
end

%-------LOAD PARAMETERS------------
%----------------------------------
condition_names = strsplit(condition_names,',');
conditions_marks = strsplit(condition_marks,',');
assert(length(condition_names)==length(conditions_marks), 'Input condition names and marks are incorrect.')

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
    EEG = pop_loadset('filename',file_name,'filepath', path_to_files);
    EEG = eeg_checkset( EEG );
    
    events = {EEG.event(:).type};
            
    for cond = 1 : length(condition_names)
        condition_name = condition_names{cond};
        condition_marks = conditions_marks{cond};
        marks = strsplit(condition_marks,' ');
                           
        %search indices where strings for marks and events are equal        
        %TODO due to compatibility issues with Matlab12 the following line
        %was replaced by the following for
        %indices_condition = find(ismember(events,condition_marks)); 
        
        events_nr = length(events);
        indices_condition = [];
        for e = 1 : events_nr
            ev = events{e};
            if isnumeric(ev)
                ev = num2str(ev);
            end
            if any(strcmp(marks,ev))
                indices_condition = [indices_condition e];
            end
        end

        for e = 1 : length(indices_condition)

            EEG.event(indices_condition(e)).type = condition_name;
            %EEG.epoch(indices_condition(e)).type = condition_name;
        end
    end
    
    EEG = eeg_checkset(EEG, 'eventconsistency'); 
    EEG = pop_saveset( EEG, 'filename',file_name,'filepath',path_to_save);
    disp(['Saving new .set with modified marks as ' fullfile(path_to_save,file_name)])
end

