%% config
script_dir = fileparts(mfilename('fullpath')); % '/Volumes/Hera/Projects/7TBrainMech/scripts/eeg'
if isempty(script_dir), script_dir = '/Volumes/Hera/Projects/7TBrainMech/scripts/eeg'; end
eeglabpath = fullfile(script_dir,'toolbox/eeglab14_1_2b');
addpath(eeglabpath)

%% run one (example)
clean_eeg('/Volumes/Hera/Raw/EEG/7TBrainMech/10129_20180919/10129_20180919_anti.bdf',64,...
          '../../subjs/10129_20180919')


%% run for all subjects
% 

% files=dir('/Volumes/Hera/Raw/EEG/7TBrainMech/*/*bdf'); %create list of RawDataLocation contents

