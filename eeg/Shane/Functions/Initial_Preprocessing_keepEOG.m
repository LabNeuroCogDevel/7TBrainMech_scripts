function [channels_removed, data_removed, epochs_removed] = Initial_Preprocessing_keepEOG(inputfile, lowBP, topBP, outpath, FLAG, condition, varargin)

addpath(genpath('Functions'));
addpath(genpath('Functions/resources'));
addpath(('/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/'))
addpath(hera('/Projects/7TBrainMech/scripts/fieldtrip-20220104'))
ft_defaults
addpath(genpath(hera('Projects/7TBrainMech/scripts/eeg/Shane/Functions/resources/eeglab2022.1')))
addpath(genpath(hera('Projects/7TBrainMech/scripts/eeg/Shane/Resting_State/ICAwhole')))

%% cap locations
cap_location = fullfile(eeglabpath,'/plugins/dipfit/standard_BESA/standard-10-5-cap385.elp');
if ~exist(cap_location, 'file'), error('cannot find file for 128 channel cap: %s', cap_location), end
correction_cap_location = hera('Projects/7TBrainMech/scripts/eeg/Shane/Functions/resources/ChanLocMod128to64.ced');
if ~exist(correction_cap_location, 'file'), error('cannot find file for correction 128 channel cap: %s', correction_cap_location), end



commonPlus = {'AFz','C1','C2','C3','C4','C5','C6','CP1','CP2','CP3','CP4',...
    'CP5','CP6','CPz','Cz','F1','F2','F3','F4','F5','F6','F7','F8','FC1',...
    'FC2','FC3','FC4','FC5','FC6','FCz','Fp1','Fp2','FT10','FT9','Fz','I1',...
    'I2','O1','O2','Oz','P1','P10','P2','P3','P4','P5','P6','P7','P8','P9',...
    'PO10','PO3','PO4','PO7','PO8','PO9','POz','Pz','T7','T8',...
    'AF8','AF7','AF4','AF3', 'EX3', 'EX4'};% This
% check if we've already run subject
% if we have, read in what we need from set file

    % load EEG set and re- referance
    EEG = pop_loadset(inputfile);
    
    if size(EEG.data,1) < 100
        Flag128 = 0;
        EEG = pop_reref(EEG, [65 66]); %does this "restore" the 40dB of "lost SNR" ? -was it actually lost? ...this is potentially undone by PREP
        EEG = eeg_checkset(EEG);
        % find the cap to use
    else
        %[129 130] are the mastoid externals for the 128 electrode
        EEG = pop_reref(EEG, [129 130]); %does this "restore" the 40dB of "lost SNR" ? -was it actually lost? ...this is potentially undone by PREP
        EEG = eeg_checkset(EEG);
    end
    
    %stores EEG set in ALLEEG, give setname
    ALLEEG = [];
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,...
        'setname',currentName,...
        'gui','on');
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    
    % split 10129_20180919_mgs_Rem into
    %    subj=10129_20180919    and    condition=mgs_Rem
    EEG.subject = currentName(1:findstr(currentName,'mgs')-2);
    EEG.condition =  currentName(findstr(currentName,'mgs'):end);
    
    %% Filtering
    
    %band-pass filter between low and max boundle (or 1 and 90 Hz)
    % TODO: params are
    %  EEG, locutoff, hicutoff, filtorder, revfilt, usefft, plotfreqz, minphase);
    % why 3380, 0, [], 0
    % > Warning: Transition band is wider than maximum stop-band width.
    % For better results a minimum filter order of 6760 is recommended.
    % Reported might deviate from effective -6dB cutoff frequency.
    % [FLAGexist] = checkdone(fullfile(outpath,filter_folder,[currentName '_filtered']));
    
    EEG = pop_eegfiltnew(EEG, lowBP, topBP, 3380, 0, [], 0);
    % filtorder = 3380 - filter order (filter length - 1). Mandatory even. performing 3381 point bandpass filtering.
    % pop_eegfiltnew() - transition band width: 0.5 Hz
    % pop_eegfiltnew() - passband edge(s): [0.5 90] Hz
    % pop_eegfiltnew() - cutoff frequency(ies) (-6 dB): [0.25 90.25] Hz
    % pop_eegfiltnew() - filtering the data (zero-phase)
    
    %give a new setname and overwrite unfiltered data
    EEG = pop_editset(EEG,'setname',[currentName '_bandpass_filtered']);
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    
    
    % %50 hz notch filter: 47.5-52.5
    % EEG = pop_eegfiltnew(EEG, 47.5,52.5,826,1,[],0);
    
    %% Resample data
    
    % Downsample the data to 150Hz using antialiasing filter
    EEG = pop_resample(EEG, 150, 0.8, 0.4); %0.8 is fc and 0.4 is dc. Default is .9 and .2. We dont know why Alethia changed them
    
    % Downsample the data to 512Hz
    % EEGb = pop_resample( EEG, 512);
    EEG = eeg_checkset(EEG);
    
    %change setname
    EEG = pop_editset(EEG,'setname',[currentName '_filtered']);
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
    %save filtered data
    EEG = pop_saveset( EEG, 'filename',[currentName '_filtered'], ...
        'filepath',fullfile(outpath,filter_folder));
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
end

%% CHANNELS
% remove external channels
EEGupdate = pop_select( EEG,'nochannel',{'EX5' 'EX6' 'EX7' 'EX8' 'EXG1' 'EXG2' 'EXG5' 'EXG6' 'EXG7' 'EXG8' 'GSR1' 'GSR2' 'Erg1' 'Erg2' 'Resp' 'Plet' 'Temp' 'FT7' 'FT8' 'TP7' 'TP8' 'TP9' 'TP10'});

[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
%import channel locations

%change this maybe
% eeglab should have already been added with addpath

EEG=pop_chanedit(EEGupdate, 'lookup', cap_location);

if size(EEG.data,1) > 100
    EEG = pop_select( EEG,'channel',commonPlus);
    EEG = pop_chanedit(EEG, 'load', {correction_cap_location 'filetype' 'autodetect'});
    % 128    'AF8' --> 64    'AF6'
    % 128    'AF7' --> 64    'AF5'
    % 128    'AF4' --> 64    'AF2'
    % 128    'AF3' --> 64    'AF1'
    Flag128 = 1;
end
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

EEG = pop_saveset(EEG, 'filename', ['exampleSubwithEOG_10997_20200221.set'], 'filepath', outpath);


inputfile = hera('\Projects\7TBrainMech\scripts\eeg\Shane\Prep\exampleSubwithEOG_10997_20200221.set');
clear xNEW

    hdr = ft_read_header(inputfile);
    data = ft_read_data(inputfile, 'header', hdr);
    events = ft_read_event(inputfile, 'header', hdr);
    
   
    cfg = [];
    cfg.dataset = inputfile;
    cfg.headerfile = inputfile;
    cfg.channel =   {'all', '-POz'};
    cfg.trialdef.eventtype = 'trigger';
    cfg.trialdef.eventvalue = '4';
    cfg.trialdef.prestim = 0;
    cfg.trialdef.poststim = 6;
    cfg.trialfun = 'ft_trialfun_general';
%     cfg.trialdef.ntrials = 197;
    cfg.event = events;
    
    if ~ischar(cfg.event(1).value)
        
        newevents = cfg.event;
        for j = 1:length(newevents)
            newevents(j).value = num2str(newevents(j).value);
        end
        cfg.event = newevents;
        
    end

    [cfg]= ft_definetrial(cfg);

    [dataLong] = ft_preprocessing(cfg);
    
    
    %redefine the trails to be between 3-4 seconds of the delay period
    cfg = [];
    cfg.toilim = [3 4];
    [dataShort] = ft_redefinetrial(cfg, dataLong);
            
    for j = 1:length(dataShort.trial) %trial
        
        trialData = (dataShort.trial{1,j});
        ChannelTrialData{j} = trialData(:,:);
        
    end
    
%     avgData = squeeze(mean(allData, 1));
    
    xNEW = ChannelTrialData;
    
%% Gamma Analysis 
eventBand = [35,65]; %Frequency range of spectral events
fVec = (20:70); %Vector of fequency values over which to calculate TFR
Fs = 150; %Sampling rate of time-series
findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
vis = false; %Generate standard visualization plots for event features across all subjects/sessions
tVec = (1/Fs:1/Fs:1);
tVec = (1:151)/Fs;

for c = [65] %channels
    for s = 1:length(xNEW)%subject
        clear oneChannel_allTrials
        for t = 1:length(xNEW)  %trials
            
        oneChannel_allTrials(t,:) =  xNEW{1,t}(c,:); %subject s, trial t, channel c
%         classLabels{s} = 4+zeros(1,length(xNEW{1,s}) ); %needs to be the same length as the trial number 

        end
        
        oneChannel_allSubjects{s} = oneChannel_allTrials';

    end
        [specEv_struct, TFRs, X, tvec] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis, oneChannel_allSubjects{1,1}, classLabels);
%         spevEV_struct_allChannels{c} = specEv_struct; 
%         TFRs_allChannels{c} = TFRs; 
%         X_allChannels{c} = X; 
        spectralevents_vis_resub(cfg,  specEv_struct,  X, TFRs, tvec, fVec) % to only plot trials 1-10 instead of random ones

        %save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_specEV_allChannels.mat'), 'spevEV_struct_allChannels','-v7.3')
        fprintf('c = %.0f', c); 
end


