function [ epochstofind ] = extraepochs( inputfile,epochstofind,wind)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% where to find eeglab stuff
eeglabpath = fileparts(which('eeglab'));
addpath(eeglabpath)
eeglab
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

if ~exist(inputfile), error('inputfile "%s" does not exist!', inputfile), end 
[d, currentName, ext ] = fileparts(inputfile);

% to know how far your script is with running
fprintf('==========\n%s\n==========\n', currentName)

EEG = pop_loadset(inputfile);

list = {EEG.event.type};

%run this if list is numbers and should be string
if strncmp(class(epochstofind{1}.mark), 'char', 4)
    list = cellfun(@(x) num2str(x), list, 'UniformOutput', false);
    warning ('modifying list of EEG event types to be cell array of chars')
end

%% Events by type
for m = 1:length(epochstofind)
    mark = epochstofind{m}.mark;
    outputdir =epochstofind{m}.outputdir;
    outname =epochstofind{m}.name;
    
    
    if length(find(strcmp(mark,list)))>5
        EEGm = eeg_checkset( EEG );
        EEGm = pop_epoch( EEGm, {mark}, [wind], 'newname', [outname '_epochs'], 'epochinfo', 'yes');
        EEGm = pop_rmbase( EEGm, [wind(1,1)*1000    0]);
        
        epochstofind{m}.nepocs = length([EEGm.epoch]);
        
        EEGm.subject = [currentName,'_',outname];
        EEGm.condition =  outname;
        
        %save epoched data
        EEGm = pop_saveset( EEGm, 'filename',[currentName '_' outname], 'filepath',outputdir);
    else
        disp(['Subject ' currentName ' do not have less than 5 epochs for condition' outname])
        epochstofind{m}.nepocs = length(find(strcmp(mark, list)));
    end
end

