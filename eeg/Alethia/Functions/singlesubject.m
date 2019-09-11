function [channels_removed,data_removed,epochs_removed] = singlesubject(inputfile, lowBP, topBP, outpath, FLAG)

% what file are we using
if ~exist(inputfile), error('inputfile "%s" does not exist!', inputfile), end 
[d, currentName, ext ] = fileparts(inputfile);

% where to save things
filter_folder = 'filtered';
chanrj_folder = 'channels_rejected';
epoch_folder = 'epoched';
epoch_rj_marked_folder = 'marked_epochs';
epochrj_folder = 'rejected_epochs';

%to know how far your script is with running
disp(currentName)

% check if we've already run subject
epochrj = fullfile(outpath, epochrj_folder, [currentName '_Rem_epochs_rj.set']);
if exist(epochrj)
   warning('%s already complete (have "%s")!  todo load from file', currentName, epochrj)
   rj = pop_loadset(epochrj)
  % SS_chanels = rj.channels_rj
   %pop_loadset(): loading file Prep/epoched/10129_20180919_mgs_Rem_epochs.set
end

% find the cap to use
eeglabpath = fileparts(which('eeglab'));
cap_location = fullfile(eeglabpath,'/plugins/dipfit2.3/standard_BESA/standard-10-5-cap385.elp');
if ~exist(cap_location, 'file'), error('cannot find cap elp file: %s', cap_location), end


% allocate cells
channels_removed = cell(3,1,1);
data_removed = cell(3,1,1);
epochs_removed = cell(3,1,1);

%load EEG set
EEG = pop_loadset('filename',[currentName,'.set'],'filepath', d);

if(size(EEG.data,1)<100)
   EEG = pop_reref( EEG, [65 66] ); %does this "restore" the 40dB of "lost SNR" ? -was it actually lost? ...this is potentially undone by PREP
   EEG = eeg_checkset( EEG );
else
    %[129 130] are the mastoid externals for the 128 electrode
    EEG = pop_reref( EEG, [129 130] ); %does this "restore" the 40dB of "lost SNR" ? -was it actually lost? ...this is potentially undone by PREP
    EEG = eeg_checkset( EEG );
end

%stores EEG set in ALLEEG, give setname
ALLEEG = [];
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,...
    'setname',currentName,...
    'gui','off');

EEG.subject = currentName(1:findstr(currentName,'mgs')-2);
EEG.condition =  currentName(findstr(currentName,'mgs'):end);

%band-pass filter between low and max boundle (or 1 and 90 Hz)
EEG = pop_eegfiltnew(EEG, lowBP,topBP,3380,0,[],0);

%give a new setname and overwrite unfiltered data
EEG = pop_editset(EEG,'setname',[currentName '_bandpass_filtered']);

% %50 hz notch filter: 47.5-52.5
% EEG = pop_eegfiltnew(EEG, 47.5,52.5,826,1,[],0);
    
%change setname
EEG = pop_editset(EEG,'setname',[currentName '_filtered']);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
 
%save filtered data
EEG = pop_saveset( EEG, 'filename',[currentName '_filtered'], ...
    'filepath',sprintf('%s/%s/',outpath,filter_folder));
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    

%% CHANELS
% remove external channels
EEG = pop_select( EEG,'nochannel',{'EX1' 'EX2' 'EX3' 'EX4' 'EX5' 'EX6' 'EX7' 'EX8'});
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
%with big std's --> manual
% stdData = std(EEG.data,0,2); 
% figure(idx); bar(stdData)

% %2.kurtosis
% EEG = pop_rejchan(EEG, 'elec',[1:8] ,'threshold',5,'norm','on','measure','kurt');

%3.clean_rawdata
originalEEG = EEG;
EEG = clean_rawdata(EEG, 8, [0.25 0.75], 0.7, 5, 15, 0.3); % we can discuss that
% vis_artifacts(EEG,originalEEG,'NewColor','red','OldColor','black'); 
%change setname
EEG = pop_editset(EEG,'setname',[currentName '_badchannelrj']);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

EEG = pop_saveset( EEG,'filename',[currentName '_badchannelrj'], ...
    'filepath',sprintf('%s/%s/',outpath,chanrj_folder));

[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

if ~any(find(cellfun (@any,regexpi (fieldnames(EEG.etc), 'clean_channel_mask'))));
    EEG.etc.clean_channel_mask=5;
else
end

%save the channels that were rejected in a variable
channels_removed{1} = [currentName '_badchannelrj']; %setname
channels_removed{2} = setdiff({originalEEG.chanlocs.labels},{EEG.chanlocs.labels}, 'stable');
channels_removed{3} = find(EEG.etc.clean_channel_mask==0);
%also save the channels that were rejected in the EEG struct
EEG.channels_rj = setdiff({originalEEG.chanlocs.labels},{EEG.chanlocs.labels}, 'stable');
EEG.channels_rj_nr = length(setdiff({originalEEG.chanlocs.labels},{EEG.chanlocs.labels}, 'stable'));

%save the proportion of the dataset that were rejected in a variable
data_removed{1} = [currentName '_baddatarj']; %setname
data_removed{2} = length(find(EEG.etc.clean_sample_mask==0))/EEG.srate;%
data_removed{3} = length(find(EEG.etc.clean_sample_mask==0))/length(EEG.etc.clean_sample_mask);%
%also save the data that were rejected in the EEG struct
EEG.data_rj =length(find(EEG.etc.clean_sample_mask==0))/EEG.srate;%
EEG.data_rj_nr = length(find(EEG.etc.clean_sample_mask==0))/length(EEG.etc.clean_sample_mask);%

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
    'filepath',sprintf('%s/%s/',outpath,epoch_rj_marked_folder));
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%save the epochs that were rejected in a variable
epochs_removed{1} = [currentName '_badepochrj']; %setname
epochs_removed{2} = length(find(EEG.reject.rejjp))/EEG.trials;
epochs_removed{3} = length(find(EEG.reject.rejjp));
%also save the epochs that were rejected in the EEG struct
EEG.epoch_rj = length(find(EEG.reject.rejjp))/EEG.trials;
EEG.epoch_rj_nr = length(find(EEG.reject.rejjp));

%reject epochs
EEG = pop_rejepoch( EEG, find(EEG.reject.rejjp) ,0);

%save epochs rejected EEG data
EEG = pop_editset(EEG,'setname',[currentName '_epochs_rj']);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

EEG = pop_saveset( EEG,'filename',[currentName '_epochs_rj'], ...
    'filepath',sprintf('%s/%s/',outpath,epochrj_folder));
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);


%% run ICA
% replaced with `rjpath`
% rjpath = fullfile(outpath, epochrj_folder, [sujname, '*']);
%[~, subjname, ~] = fileparts(setfiles{i})
icaout = fullfile(outpath, 'ICA');
runICAss(epochrj, SS_chanels, icaout)
