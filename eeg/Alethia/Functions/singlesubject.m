function [channels_removed, data_removed, epochs_removed] = singlesubject(inputfile, lowBP, topBP, outpath, FLAG, varargin)

% what file are we using
if ~exist(inputfile), error('inputfile "%s" does not exist!', inputfile), end 
[d, currentName, ext ] = fileparts(inputfile);

% to know how far your script is with running
fprintf('==========\n%s\n==========\n', currentName)

% where to find eeglab stuff
eeglabpath = fileparts(which('eeglab'));

% where to save things
filter_folder = 'filtered';
chanrj_folder = 'channels_rejected';
epoch_folder = 'epoched';
epoch_rj_marked_folder = 'marked_epochs';
epochrj_folder = 'rejected_epochs';
icaout = fullfile(outpath, 'ICA');

% and what files will we create
chrm_name   = [currentName '_badchannelrj'];
epochrj_name = [currentName '_epochs_rj'];
% FIXME: these is not actually used!? but is recoreded in data_removed WF20190911 
datarm_name = [currentName '_baddatarj']; 
epochrm_name = [currentName '_badepochrj'];
% TODO: collect other pop_saveset filenames here

% check if we've already run subject 
% if we have, read in what we need from set file
epochrj = fullfile(outpath, epochrj_folder, [epochrj_name '.set']);
if exist(epochrj, 'file')
   warning('%s already complete (have "%s")! todo load from file', currentName, epochrj)
   rj = pop_loadset(epochrj);
   channels_removed = {chrm_name, rj.channels_rj, find(rj.etc.clean_channel_mask==0)}';
   data_removed = {datarm_name, rj.data_rj, rj.data_rj_nr}';
   epochs_removed = {epochrm_name, rj.epoch_rj, rj.epoch_rj_nr}';
   % ica wont rerun if already run
   runICAss(epochrj, icaout)
   return
end

% allocate cells
channels_removed = cell(3,1,1);
data_removed = cell(3,1,1);
epochs_removed = cell(3,1,1);

%load EEG set
EEG = pop_loadset(inputfile);

if size(EEG.data,1) < 100
   EEG = pop_reref(EEG, [65 66]); %does this "restore" the 40dB of "lost SNR" ? -was it actually lost? ...this is potentially undone by PREP
   EEG = eeg_checkset(EEG);
   % find the cap to use
   cap_location = fullfile(eeglabpath,'/plugins/dipfit2.3/standard_BESA/standard-10-5-cap385.elp');
   if ~exist(cap_location, 'file'), error('cannot find 64 channel cap elp file: %s', cap_location), end
else
    %[129 130] are the mastoid externals for the 128 electrode
    EEG = pop_reref(EEG, [129 130]); %does this "restore" the 40dB of "lost SNR" ? -was it actually lost? ...this is potentially undone by PREP
    EEG = eeg_checkset(EEG);
    % TODO: find cap 
    cap_location = [];
    if ~exist(cap_location, 'file'), error('cannot find file for 128 channel cap: %s', cap_location), end
end

%stores EEG set in ALLEEG, give setname
ALLEEG = [];
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,...
    'setname',currentName,...
    'gui','off');

% split 10129_20180919_mgs_Rem into 
%    subj=10129_20180919    and    condition=mgs_Rem
EEG.subject = currentName(1:findstr(currentName,'mgs')-2);
EEG.condition =  currentName(findstr(currentName,'mgs'):end);

%band-pass filter between low and max boundle (or 1 and 90 Hz)
% TODO: params are
%  EEG, locutoff, hicutoff, filtorder, revfilt, usefft, plotfreqz, minphase);
% why 3380, 0, [], 0
% > Warning: Transition band is wider than maximum stop-band width. 
% For better results a minimum filter order of 6760 is recommended. 
% Reported might deviate from effective -6dB cutoff frequency.
EEG = pop_eegfiltnew(EEG, lowBP, topBP, 3380, 0, [], 0);
% filtorder = 3380 - filter order (filter length - 1). Mandatory even. performing 3381 point bandpass filtering.
% pop_eegfiltnew() - transition band width: 0.5 Hz
% pop_eegfiltnew() - passband edge(s): [0.5 90] Hz
% pop_eegfiltnew() - cutoff frequency(ies) (-6 dB): [0.25 90.25] Hz
% pop_eegfiltnew() - filtering the data (zero-phase)

%give a new setname and overwrite unfiltered data
EEG = pop_editset(EEG,'setname',[currentName '_bandpass_filtered']);

% %50 hz notch filter: 47.5-52.5
% EEG = pop_eegfiltnew(EEG, 47.5,52.5,826,1,[],0);
 
% Downsample the data to 100Hz using antialiasing filter
EEG = pop_resample(EEG, 100, 0.8, 0.4);
% % Downsample the data to 512Hz
% EEGb = pop_resample( EEG, 512);
EEG = eeg_checkset(EEG);

%change setname
EEG = pop_editset(EEG,'setname',[currentName '_filtered']);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
 
%save filtered data
EEG = pop_saveset( EEG, 'filename',[currentName '_filtered'], ...
    'filepath',fullfile(outpath,filter_folder));
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    

%% CHANELS
% remove external channels
EEG = pop_select( EEG,'nochannel',{'EX1' 'EX2' 'EX3' 'EX4' 'EX5' 'EX6' 'EX7' 'EX8' 'EXG3' 'EXG4' 'EXG5' 'EXG6' 'EXG7' 'EXG8' 'GSR1' 'GSR2' 'Erg1' 'Erg2' 'Resp' 'Plet' 'Temp'});

[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); 
%import channel locations

%change this maybe
% eeglab should have already been added with addpath
EEG=pop_chanedit(EEG, 'lookup', cap_location);

[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%% bad channel rejection

%bad channels are in general the channels that you can't save even if you
%reject 5-10% of your datapoints

%different options for channel rejection are displayed. Option 3 is ued.

% %1.look at standard deviation in bar plots and remove the channels
% with big std's --> manual
% stdData = std(EEG.data,0,2); 
% figure(idx); bar(stdData)

% %2.kurtosis
% EEG = pop_rejchan(EEG, 'elec',[1:8] ,'threshold',5,'norm','on','measure','kurt');

%3.clean_rawdata
originalEEG = EEG;
EEG = clean_rawdata(EEG, 8, [0.25 0.75], 0.7, 5, 15, 0.3); % we can discuss that
% vis_artifacts(EEG,originalEEG,'NewColor','red','OldColor','black'); 
%change setname
EEG = pop_editset(EEG,'setname', chrm_name);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

EEG = pop_saveset( EEG,'filename', chrm_name, ...
    'filepath',sprintf('%s/%s/',outpath,chanrj_folder));

[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

if ~any(find(cellfun (@any,regexpi (fieldnames(EEG.etc), 'clean_channel_mask'))));
    EEG.etc.clean_channel_mask=42;
else
end

%save the channels that were rejected in a variable
channels_removed{1} = chrm_name; %setname
channels_removed{2} = setdiff({originalEEG.chanlocs.labels},{EEG.chanlocs.labels}, 'stable');
channels_removed{3} = find(EEG.etc.clean_channel_mask==0);
%also save the channels that were rejected in the EEG struct
EEG.channels_rj = channels_removed{2};
EEG.channels_rj_nr = length(EEG.channels_rj);

%save the proportion of the dataset that were rejected in a variable
data_removed{1} = datarm_name; %setname
data_removed{2} = length(find(EEG.etc.clean_sample_mask==0))/EEG.srate;%
data_removed{3} = length(find(EEG.etc.clean_sample_mask==0))/length(EEG.etc.clean_sample_mask);%
%also save the data that were rejected in the EEG struct
EEG.data_rj    = data_removed{2};
EEG.data_rj_nr = data_removed{3};

%% interpolate channels

EEG = pop_interp(EEG, originalEEG.chanlocs, 'spherical');

% eeglab redraw
%% re-reference: average reference
if FLAG
EEG = pop_reref( EEG, []);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,...
    'setname',[currentName '_avref'],...
    'gui','off'); 

else
end
%% epoching: -0.250 to 3 seconds
%extract epochs
EEG = pop_epoch( EEG, {'-5' '-3' '0' '1' '2' '3' '4' '5'}, [-0.250  3], 'newname', [currentName '_epochs'], 'epochinfo', 'yes');

%remove baseline
EEG = pop_rmbase( EEG, [-250    0]);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'overwrite','on','gui','off');

%save epoched eegsets
EEG = pop_saveset( EEG,'filename',[currentName '_epochs'], ...
    'filepath',sprintf('%s/%s/',outpath,epoch_folder));
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
%% epoch rejection

% ~10% should be rejected. 

%Two options for epoch rejection: 2nd option is used.

%1. kurtosis
%kurtosis (not recommended): default 5 for maximum threshold limit. Try that, check how many
%epochs removed, otherwise higher to 8-10. 
% EEG = pop_autorej(EEG, 'nogui','on','eegplot','off');

%2.Use improbability and thresholding
%Apply amplitude threshold of -500 to 500 uV to remove big
% artifacts(don't capture eye blinks)
EEG = pop_eegthresh(EEG,1,[1:EEG.nbchan],-500,500,0,EEG.xmax,0,1);


%apply improbability test with 6SD for single channels and 2SD for all channels,
EEG = pop_jointprob(EEG,1,[1:EEG.nbchan],6,2,0,0,0,[],0);

%save marked epochs (to check later if you agree with the removed opochs)
EEG = pop_editset(EEG,'setname',[currentName '_epochs_marked']);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

EEG = pop_saveset( EEG,'filename',[currentName '_epochs_marked'], ...
    'filepath',fullfile(outpath, epoch_rj_marked_folder));
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%save the epochs that were rejected in a variable
epochs_removed{1} = epochrm_name; %setname
epochs_removed{2} = length(find(EEG.reject.rejjp))/EEG.trials;
epochs_removed{3} = length(find(EEG.reject.rejjp));
%also save the epochs that were rejected in the EEG struct
EEG.epoch_rj = epochs_removed{2};
EEG.epoch_rj_nr = epochs_removed{3};

%reject epochs
EEG = pop_rejepoch(EEG, find(EEG.reject.rejjp), 0);

%save epochs rejected EEG data
EEG = pop_editset(EEG, 'setname', epochrj_name);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

EEG = pop_saveset(EEG, 'filename', epochrj_name, 'filepath', fullfile(outpath,epochrj_folder));
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);


%% run ICA
% replaced with `rjpath`
%[~, subjname, ~] = fileparts(setfiles{i})
% rjpath = fullfile(outpath, epochrj_folder, [sujname, '*']);
runICAss(epochrj, icaout)
