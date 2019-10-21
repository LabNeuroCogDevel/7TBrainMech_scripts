function [  ] = grandaverage(datapath,outputname,condition)
% uses eeglab14_1_2b\plugins\grandaverage
%UNTITLED5 Summary of this function goes here
% where to find eeglab stuff
eeglabpath = hera('Projects/7TBrainMech/scripts/Alethia/Functions/resources/Euge/Toolbox_v2018');
addpath(genpath('\Projects\7TBrainMech\scripts\eeg\Alethia\Functions\resources\Euge\Toolbox_v2018\Toolbox_v2018\eeglab14_1_1b\plugins\grandaverage')); 
addpath(eeglabpath)
eeglab
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

current = pwd;

setfiles0 = dir([datapath '/*.set']);
usefiles = strfind({setfiles0.name}',condition);
subjnum_sp =find(~cellfun(@isempty,usefiles));

setfiles = {setfiles0(subjnum_sp).name}; % cell array with EEG file names
EEG = pop_grandaverage(setfiles, 'pathname', [datapath,'/']);
cd(datapath)
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'setname',outputname,'savenew',outputname,'gui','off'); 

cd(current)
end

