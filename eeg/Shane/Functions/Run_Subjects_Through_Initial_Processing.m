% script to run all subjects in parallel --  wraps around
% singlesubject('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Prep/remarked/10129_20180919_mgs_Rem.set', 0.5, 90, '/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Prep', 1)
tic

%% paths
addpath(genpath('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Functions'));
run('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/resources/eeglab2022.1/eeglab.m');

%% settings
only128 = 0; % 0==do all, 1==only 128 channel subjects
condition = 1; %0 - if you want to overwrite an already existing file; 1- if you want it to skip subjects who have already been run through singlesubject

% preproc settings
lowBP = 0.5;
topBP = 70;
FLAG = 1;

%Outpath
outpath = hera('Projects/7TBrainMech/scripts/eeg/Shane/SNR');

% run remarked to pull files fro database 
%MGS
remarcadata

%SNR 
remarked_data_SNR

%% files
% bdf -> set after simplifying epoch markers (TTL labels)
    
tic
if only128
    setfiles = all_remarked_set('only128', true);
else
    %MGS
    %setfiles = all_remarked_set();
    
    %Resting State 
    %setfiles = all_remarked_set_RestingState();

    %Aud Steady State 
    %setfiles = all_remarked_set_RestingState();

    %SNR
    setfiles = all_remarked_set_SNR();

end
% 
    
% redo = [11694];
% for i = 1: length(redo) 
%     file = sprintf('Projects/7TBrainMech/scripts/eeg/Shane/Prep/remarked/%d', redo(i));
%     setfiles = dir(hera([file '*_*.set']));
%     setfiles = arrayfun(@(x) fullfile(x.folder, x.name), setfiles(~[setfiles.isdir]), 'Uni',0); % cell array with EEG file names
%     allfiles(i,:) = setfiles; 
% end

%setfiles =  allfiles;


%% allocate cell
%create empty variables
n = size(setfiles,1); %number of EEG sets to preprocess
fprintf('running for %d set files\n', n)
channels_removed = cell(3, n, 1);
data_removed     = cell(3, n, 1);
epochs_removed   = cell(3, n, 1);


%% cleaning
for i = 1:n
    % run through single subject preprocessing
    inputfile = setfiles{i};
    try
       % MGS
       %[SS_chanels, SS_rdata, SS_repoch] = Initial_Preprocessing(inputfile, lowBP, topBP, outpath, FLAG, condition);

       % resting state
       %[SS_chanels, SS_rdata, SS_repoch] = Initial_Preprocessing_RestingState(inputfile, lowBP, topBP, outpath, FLAG, condition);
       
       
       % Aud SS
       %[SS_chanels, SS_rdata, SS_repoch] = Initial_Preprocessing_keepEOG(inputfile, lowBP, topBP, outpath, FLAG, condition);
        
       % SNR
       [SS_chanels, SS_rdata, SS_repoch] = Initial_Preprocessing_SNR(inputfile, lowBP, topBP, outpath, FLAG, condition);


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

%% time info
toc,
disp(datetime)
