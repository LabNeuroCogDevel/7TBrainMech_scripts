%% paths
addpath(genpath('Functions'));
eeglab

%% Channels ans epoch check

name = '10129_20180919_mgs_Rem_epochs_rj_ICA_icapru.set';
outpath = '/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Alethia/Prep/ICAPrerCheck';
EEG = pop_loadset('filename',name,'filepath','/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Alethia/Prep/ICAclean/');

figure; pop_spectopo(EEG, 1, [-400  1990], 'EEG' , 'freq', [6 10 22], 'freqrange',[2 25],'electrodes','off');
 
bad_channels = [64 63];

EEG = pop_interp(EEG, bad_channels, 'spherical');
%% epoch rejection

EEG = pop_saveset( EEG,'filename',[name(1:end-11) '_posticacleanCH'], ...
    'filepath',outpath);
% ~10% should be rejected. 

%Two options for epoch rejection: 2nd option is used.

%1. kurtosis
%kurtosis (not recommended): default 5 for maximum threshold limit. Try that, check how many
%epochs removed, otherwise higher to 8-10. 

EEG = pop_autorej(EEG, 'nogui','on','eegplot','on');

% EEG = pop_saveset( EEG,'filename',[name(1:end-11) '_posticacleanEP'], ...
%     'filepath',outpath);% %2.Use improbability and thresholding
% %Apply amplitude threshold of -500 to 500 uV to remove big
% % artifacts(don't capture eye blinks)
% % EEG = pop_eegthresh(EEG,1,[1:EEG.nbchan],-.2,.2,0,EEG.xmax,0,0);
% 
% %apply improbability test with 6SD for single channels and 2SD for all channels,
% % EEG = pop_jointprob(EEG,1,[1:EEG.nbchan],1,2,0,0,0,[],0);
% 
% %save marked epochs (to check later if you agree with the removed opochs)
% EEG = pop_editset(EEG,'setname',[name '_posticaclean']);
% eeglab redraw
% 
% Nepochrej = length(find(EEG.reject.rejauto)); 
% EEG = pop_saveset( EEG,'filename',[name(1:end-11) '_posticaclean'], ...
%     'filepath',outpath);
