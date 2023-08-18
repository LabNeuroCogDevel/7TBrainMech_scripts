% EEGLAB history file generated on the 01-Jul-2022
% ------------------------------------------------
addpath(genpath('Functions'));
addpath(genpath(hera('Projects/7TBrainMech/scripts/eeg/toolbox/eeglab14_1_2b')))

eeglab

addpath(('/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/'))
addpath(genpath('Functions'));
addpath(hera('/Projects/7TBrainMech/scripts/fieldtrip-20191127'))
ft_defaults

datapath = hera('/Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/AfterWhole/ICAwholeClean_homogenize');

%load in all the data files
setfiles0 = dir([datapath,'/*icapru.set']);
setfiles = {};

for epo = 1:length(setfiles0)
    setfiles{epo,1} = fullfile(datapath, setfiles0(epo).name); % cell array with EEG file names
    % setfiles = arrayfun(@(x) fullfile(folder, x.name), setfiles(~[setfiles.isdir]),folder, 'Uni',0); % cell array with EEG file names
end

for j = 1 : length(setfiles0)
    
    idvalues(j,:) = (setfiles0(j).name(1:14));
end


numSubj = length(idvalues);
x = cell(1,numSubj);
Subjects = cell(1,numSubj);

channelERSP = cell(1,64);


clear x
clear Subjects

for i = 1:numSubj
    inputfile = setfiles{i};
    subject = inputfile(94:107);
    
   
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_loadset(inputfile);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    
    if ~ischar(EEG.event(1).type)
        
        newevents = EEG.event;
        for j = 1:length(newevents)
            newevents(j).type = num2str(newevents(j).type);
        end
        EEG.event = newevents;
        
    end
    
    try
        
        EEG = pop_epoch( EEG, {  '4'  }, [-0.2 1], 'epochinfo', 'yes');
        
    catch
        warning('%s wont run through epoch', subject)
        wontRun{i} = subject;
        continue;
    end
    
    
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off');
    EEG = pop_rmbase( EEG, [-200    0]);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'gui','off');
    
    for chan = 1:64
        
        EEG = eeg_checkset( EEG );
        figure;
        [ersp itc powbase times frequencies] = pop_newtimef( EEG, 1, chan, [-200  993], [7 0.5] , 'topovec', chan, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', 'Fp1', 'baseline',[0], 'freqs', [30 75], 'plotphase', 'off', 'padratio', 1);
        eeglab redraw;
       
        
        % ersp   = (nfreqs,timesout) matrix of log spectral diffs from baseline
        %                     (in dB log scale or absolute scale). Use the 'plot' output format
        %                     above to output the ERSP as shown on the plot.
        % itc    = (nfreqs,timesout) matrix of complex inter-trial coherencies.
        %                     itc is complex -- ITC magnitude is abs(itc); ITC phase in radians
        %                     is angle(itc), or in deg phase(itc)*180/pi.
        % powbase  = baseline power spectrum. Note that even, when selecting the
        %                     the 'trialbase' option, the average power spectrum is
        %                     returned (not trial based). To obtain the baseline of
        %                     each trial, recompute it manually using the tfdata
        %                     output described below.
        % times  = vector of output times (spectral time window centers) (in ms).
        % freqs  = vector of frequency bin centers (in Hz).
        
        ERSPinfo = struct('ERSP', ersp, 'ITC', itc, 'BaselinePower', powbase, 'times', times, 'frequencies', frequencies);
        channelERSP{chan} = ERSPinfo;
         close all;
    end
    
    x{i} = channelERSP;
    Subjects{i} = subject;
    
end

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/XmatrixERSP.mat'), 'x', '-v7.3')
x = load('H:\Projects\7TBrainMech\scripts\eeg\Shane\AudSteadyState\XmatrixERSP.mat');
x = x.x;

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/ERSP_Subjects.mat'), 'Subjects', '-v7.3')
Subjects = load('H:\Projects\7TBrainMech\scripts\eeg\Shane\AudSteadyState\ERSP_Subjects.mat');
Subjects = Subjects.Subjects;

hdr = ft_read_header(inputfile);
chanLabels = hdr.label;

%% Map adolescent and group averages 

agefile = readtable('H:/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/agefile_20220204.csv'); 
agefileDF = table2array(agefile); 

%% Map group average 

for i = 1:numSubj
    
    if isempty(x{i})
        continue
    else
        
        for chan = 1:64
            
            subject = x{1,i}; % select subjects cell from x matrix
            selectChannel = subject{1,chan}; % select which channel struct to analyze
           
           ERSPofInterest(i,chan,:,:) = selectChannel.ERSP;
           ITCofInterest(i,chan,:,:) = selectChannel.ITC;
           times = selectChannel.times; 
           freqs = selectChannel.frequencies; 
           
        end
  
    end
end

groupAvgERSP = squeeze(mean(ERSPofInterest,1)); 
groupAvgITC = squeeze(mean(ITCofInterest,1)); 
timefreqs = [times freqs]; 

tftopo(groupAvgERSP, times, freqs);

% trying to map topography 
chanLocs = struct2table(hdr.orig.chanlocs);
writetable(chanLocs, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/AuditorySS/ChannelLocs.csv'));

topoplot(groupAvgERSP, hdr.orig.chanlocs)

%% Find ERSP and ITC between 200 - 500ms post stimulus onset 

for i = 1:numSubj
    
    if isempty(x{i})
        continue
    else
        
        for chan = 1:64
            
            subject = x{1,i}; % select subjects cell from x matrix
            selectChannel = subject{1,chan}; % select which channel struct to analyze
            
            timePoints = find(selectChannel.times >= 150 & selectChannel.times <= 500); % find the indicies for the predetermined time points 
            freqPoints = find(selectChannel.frequencies >= 35 & selectChannel.frequencies <= 45); % find the indicies for the predetermined frequency points 

           ERSPofInterest = selectChannel.ERSP(freqPoints,timePoints);
           ITCofInterest = selectChannel.ITC(freqPoints,timePoints);

           averageERSP(i,chan) = mean(mean(ERSPofInterest, 2)); % average across time and across frequencies for each channel
           averageITC(i,chan) = mean(mean(ITCofInterest, 2)); % average across time and across frequencies for each channel
           magITC(i, chan) = abs(averageITC(i,chan)); 
           phaseITC(i, chan) = angle(averageITC(i, chan))*(180/pi);

        end
  
    end
end

groupavgERSP = mean(averageERSP,1); % average the ERSP from 35-45 Hz, across 150-500ms
groupavgITC = mean(averageITC,1); % average the ITC from 35-45 Hz, across 150-500ms
groupavgphaseITC = mean(phaseITC,1); % average the ITC phase from 35-45 Hz, across 150-500ms
groupavgmagITC = mean(magITC,1); % average the ITC mag from 35-45 Hz, across 150-500ms

topoplot(groupavgERSP, hdr.orig.chanlocs, 'maplimits', 'maxmin')

%%
AmplutideT = table('Size', [0, 6], 'VariableTypes', {'string', 'double', 'double', 'double',  'double',  'double'});
AmplutideT.Properties.VariableNames = {'Subject', 'Channel', 'ERSP','RawITC', 'ITCmagnitude', 'ITCphase'};


for isub = 1:numSubj
 
   T = table('Size', [64, 6], 'VariableTypes', {'string', 'double', 'double', 'double',  'double',  'double'});
   T.Properties.VariableNames = {'Subject', 'Channel', 'ERSP','RawITC', 'ITCmagnitude', 'ITCphase'};
   
    subjectsERSP = averageERSP(isub,:);
    subjectsITC = averageITC(isub,:); 
    subjectsMagITC = magITC(isub,:); 
    subjectsPhaseITC = phaseITC(isub,:); 

    
    subject = Subjects(isub); 
    
    T.Subject(1:64) = subject{1};
    T.ERSP = subjectsERSP'; 
    T.Channel  = chanLabels;
    T.RawITC =  subjectsITC'; 
    T.ITCmagnitude = subjectsMagITC';
    T.ITCphase = subjectsPhaseITC'; 
    
    AmplutideT = [AmplutideT;T];
    
    
end

writetable(AmplutideT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/AuditorySS/ERSP_40hz.csv'));
