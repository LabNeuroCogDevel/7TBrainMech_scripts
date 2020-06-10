a%% paths
addpath(genpath('Functions'));
addpath(hera('Projects/7TBrainMech/scripts/eeg/toolbox/eeglab14_1_2b'))

eeglab

%% Channels ans epoch check

name = '10129_20180919_mgs_Rem_epochs_rj_ICA_icapru.set';
outpath = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/ICAPrerCheck');
EEG = pop_loadset('filename',name,'filepath',hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/ICAclean/'));

figure; pop_spectopo(EEG, 1, [-400  1990], 'EEG' , 'freq', [6 10 22], 'freqrange',[2 25],'electrodes','off');
 
bad_channels = [64];

EEG = pop_interp(EEG, bad_channels, 'spherical');
%% epoch rejection
% ~10% should be rejected. 
%% Parameters
% It only looks in the important channels
chan_imp=[1:64];
% Standart deviation to try
chan_SD=6;
%% "Rej data Epochs"
% Observing large absoluate values at most electrodes or components 
% is improbable and may well mark the presence of artifact.
EEG = pop_jointprob(EEG,1,chan_imp ,chan_SD,chan_SD,0,0,0,[],0);

% Apply amplitude threshold of -75 to 75 uV to remove big artifacts
EEG = pop_eegthresh(EEG,1,[1:EEG.nbchan],-75,75,0,EEG.xmax,0,0);

% peaky distribution of activity
% EEG = pop_rejkurt(EEG,1,chan_imp ,chan_SD,chan_SD,0,0,0,[],0);

[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
eeglab redraw % redraw eeglab to show the new epoched dataset

EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);  %gives a variable
% named as follows with all epochs to reject: EEG.reject.rejglobal
pop_eegplot( EEG, 1, 1,  1);

[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
%% Conteo de epoch
% Busca los numeros de los eventos a rechazar
num_rej_events=find(EEG.reject.rejjp);

% Cantidad de trails totales
cant_tot_epoch=length(EEG.epoch);
% Cantidad de trails sacados
cant_rej_events=size(num_rej_events,2);
% Percentage
perc_rej_epoch=cant_rej_events*100/cant_tot_epoch;

%% Rechazo de epocas marcadas
EEG = pop_rejepoch( EEG, [num_rej_events] ,0);

EEG = pop_saveset( EEG,'filename',[name(1:end-11) '_posticaclean'], ...
    'filepath',outpath);
