% script to run all subjects in parallel --  wraps around
% singlesubject('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Alethia/Prep/remarked/10129_20180919_mgs_Rem.set', 0.5, 90, '/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Alethia/Prep', 1)

%% paths
addpath(genpath('Functions'));
addpath(hera('Projects/7TBrainMech/scripts/eeg/toolbox/eeglab14_1_2b'))

%% settings
lowBP = 0.5;
topBP = 90;
FLAG = 1;
outpath = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep');


%% files
% bdf -> set after simplifying epoch markers (TTL labels)
setfiles = dir(hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/remarked/*.set'));
setfiles = arrayfun(@(x) fullfile(x.folder, x.name), setfiles(~[setfiles.isdir]), 'Uni',0); % cell array with EEG file names

%% allocate cell
%create empty variables
n = size(names,2); %number of EEG sets to preprocess
channels_removed = cell(3, n, 1);
data_removed     = cell(3, n, 1);
epochs_removed   = cell(3, n, 1);

% figure needs to be up for some functions to be put in workspace?
eeglab

%% cleaning
parfor i = 1:n
    % run through single subject preprocessing
    inputfile = setfiles{i};
    try
       [SS_chanels, SS_rdata, SS_repoch] = singlesubject(inputfile, lowBP, topBP, outpath, FLAG);

       % track what is removed to save in one big list -- used for ICA within 'singlesubject'
       channels_removed(:,i) = SS_chanels;
       data_removed(:,i)     = SS_rdata;
       epochs_removed(:,i)   = SS_repoch;
   catch e
      fprintf('Error processing "%s": %s\n',inputfile, e.message)
      for s=e.stack
         disp(s)
      end
   end
end
% save what we've removed (only really need channels)
save('removed.mat', 'channels_removed','data_removed','epochs_removed')
