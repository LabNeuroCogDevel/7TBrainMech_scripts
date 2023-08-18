
% Auditory Steady State
%% Evoked Activity 
addpath(genpath('Functions'));
addpath(genpath('Functions/resources/Euge/'))

addpath(genpath(hera('Projects/7TBrainMech/scripts/eeg/Shane/Functions/resources/eeglab2022.1')))

eeglab

addpath(('/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/'))
addpath(genpath('Functions'));
addpath(hera('/Projects/7TBrainMech/scripts/fieldtrip-20220104'))
ft_defaults

datapath = hera('/Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/AfterWhole/ICAwholeClean_homogenize');

%load in all the data files
setfiles0 = dir([datapath,'/*icapru*.set']);
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

alreadyRun = load('H:\Projects\7TBrainMech\scripts\eeg\Shane\AudSteadyState\SubjectsinXmatrix.mat');
alreadyRun = alreadyRun.Subjects;  

clear x
clear Subjects

% Creat x matrix not baselined
for i = 1:numSubj
    inputfile = setfiles{i};
    subject = inputfile(94:107);
        
        if any(strcmp(alreadyRun, subject))
            warning('%s already complete', subject)
            continue
   
        else
     
        inputfile = setfiles{i};

    clear events
    clear data
    clear hdr
    clear avgData
    clear classLabels
    clear allData
    
    hdr = ft_read_header(inputfile);
    data = ft_read_data(inputfile, 'header', hdr);
    events = ft_read_event(inputfile, 'header', hdr);
    
    cfg = [];
    cfg.dataset = inputfile;
    cfg.headerfile = inputfile;
    cfg.channel =   {'all', '-POz'}; % channel POz was identified as a consistently noisey channel during the mgs preprocessing
    cfg.trialdef.eventtype = 'trigger';
    cfg.trialdef.eventvalue = '2'; % take only the sections with trigger value 4 (40 hz), 3 (30 hz), or 2 (20 hz)
    cfg.trialdef.prestim = 0.2; 
    cfg.trialdef.poststim = 1;
    cfg.trialfun = 'ft_trialfun_general';
    cfg.event = events;
   
    if ~ischar(cfg.event(1).value)
        
        newevents = cfg.event;
        for j = 1:length(newevents)
            newevents(j).value = num2str(newevents(j).value);
        end
        cfg.event = newevents;
        
    end
    
    try
        
        [cfg]= ft_definetrial(cfg);
        
    catch
        warning('%s wont run through feildtrip', subject)
        wontRun{i} = subject;
        continue;
    end
    

    
    [data] = ft_preprocessing(cfg);
    
  
    x{i} = data;
    Subjects{i} = subject;
        end
end

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/XmatrixWithallSubjects_includesPreStim_20Hz_20230206.mat'), 'x', '-v7.3')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/AllSubjects_20230108.mat'), 'Subjects', '-v7.3')


x = load('H:\Projects\7TBrainMech\scripts\eeg\Shane\AudSteadyState\XmatrixWithallSubjects_includesPreStim_20Hz_20230206.mat');
x = x.x;
% cap locations
eeglabpath = fileparts(which('eeglab'));

cap_location = 'H:\Projects\7TBrainMech\scripts\fieldtrip-20220104\template\layout\biosemi64.lay';
if ~exist(cap_location, 'file'), error('cannot find file for 128 channel cap: %s', cap_location), end

cfg.layout = cap_location;
allSubjectERPs = cell(1,numSubj);

% find ERPs for each channel (averaged across trials) for all subjects 
for i = 1:numSubj
    if isempty(x{i})
        continue
    else

erp = ft_timelockanalysis(cfg, x{i}); % finds the ERP for each channel, averaging across trials 
cfg.fontsize = 6;
cfg.showlabels = 'yes';
cfg.showoutline = 'yes';
cfg.interactive = 'yes';
% ft_multiplotER(cfg,erp);

allSubjectERPs{i} = erp; 
    end
end

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubjectERPs_includesPreStim_20hz_20230206.mat'), 'allSubjectERPs')

load('H:\Projects\7TBrainMech\scripts\eeg\Shane\AudSteadyState\allSubjectERPs_includesPreStim.mat')

% Baseline the ERPs based on 200 ms pre stim 
baselinedERPs = cell(1,numSubj);

cfg.baseline = [-.2 0];
for i = 1:numSubj
     if isempty(allSubjectERPs{i})
        continue
    else
    baselinedERPs{i} = ft_timelockbaseline(cfg,allSubjectERPs{i});
     end
%      ft_multiplotER(cfg,baselinedERPs{i})

end
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubjectERPs_baselinedERPs_20hz_20230206.mat'), 'baselinedERPs')
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\AudSteadyState\allSubjectERPs_baselinedERPs.mat')

% define the time points where you want to average the amplitude in between
% (here we are going to find the mean amplitude of the ERP between 50 - 200ms
time = [.05 .2]; 

allSubjectERPpower = cell(1,numSubj);
meanSquaredERPpower = cell(1,numSubj);
for isub = 1:numSubj
    if isempty(baselinedERPs{isub})
        continue
    else
        timePoints = find(baselinedERPs{isub}.time >= time(1) & baselinedERPs{isub}.time <= time(2)); % find the indicies for the predetermined time points 
        
        cfg = [];
        cfg.channel    = 'EEG';
        cfg.method     = 'wavelet';
        cfg.width      = 7;
        cfg.output     = 'pow';
        cfg.foi        = 30:1:70;
        cfg.toi        = 'all';
        TFRwave = ft_freqanalysis(cfg, baselinedERPs{isub}); % creates channel x freq x time point struct 

%         cfg = [];
%         cfg.showlabels   = 'yes';
%         cfg.layout       = cap_location;
%         cfg.colorbar     = 'yes';
%         cfg.masknans     = 'yes';
%         ft_multiplotTFR(cfg, TFRwave)

        
       
            selectPowerBetweenTimePoints = (TFRwave.powspctrm(:,:,timePoints)); % Select power values between 0.5 and .2 s 
            avgPower = mean(selectPowerBetweenTimePoints,3); %average power across time 
            avgPowerPerChan = mean(avgPower,2); %avg power values for all 41 points of frequency evaluated between 30 and 70 Hz
       
        
        allSubjectERPpower{isub} = avgPowerPerChan; % the mean ERP power per channel
        meanSquaredERPpower{isub} = avgPowerPerChan.^2; % mean squared power for each channel

    end
end

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubject_MeanSquaredPower_40hz.mat'), 'meanSquaredERPpower')
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\AudSteadyState\allSubject_MeanSquaredPower_20hz.mat')



%% Spontaneous Activity 

numSubj = length(idvalues);
xbaseline = cell(1,numSubj);
Subjects = cell(1,numSubj);

% Creat x matrix baselined to 200 ms prior to stimulus 
for i = 1:numSubj
    inputfile = setfiles{i};
    subject = inputfile(94:107);
    
  if any(strcmp(alreadyRun, subject))
            warning('%s already complete', subject)
            continue
    
        else
    
    inputfile = setfiles{i};
    
    clear events
    clear data
    clear hdr
    clear avgData
    clear classLabels
    clear allData
    
    hdr = ft_read_header(inputfile);
    data = ft_read_data(inputfile, 'header', hdr);
    events = ft_read_event(inputfile, 'header', hdr);
    
    cfg = [];
    cfg.dataset = inputfile;
    cfg.headerfile = inputfile;
    cfg.channel =   {'all', '-POz'}; % channel POz was identified as a consistently noisey channel during the mgs preprocessing
    cfg.trialdef.eventtype = 'trigger';
    cfg.trialdef.eventvalue = '2'; % take only the sections with trigger value 4 (40 hz), 3 (30 hz), or 2 (20 hz)
    cfg.trialdef.prestim = 0.2; 
    cfg.trialdef.poststim = 1;
    cfg.trialfun = 'ft_trialfun_general';
    cfg.event = events;
   
    if ~ischar(cfg.event(1).value)
        
        newevents = cfg.event;
        for j = 1:length(newevents)
            newevents(j).value = num2str(newevents(j).value);
        end
        cfg.event = newevents;
        
    end
    
    try
        
        [cfg]= ft_definetrial(cfg);
        
    catch
        warning('%s wont run through feildtrip', subject)
        wontRun{i} = subject;
        continue;
    end
    
    cfg.demean          = 'yes';
    cfg.baselinewindow  = [-0.2 0];
    
    [data] = ft_preprocessing(cfg);

    xbaseline{i} = data;
    Subjects{i} = subject;
  end
end

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/XmatrixWithallSubjects_baseline_20Hz_20230206.mat'), 'xbaseline', '-v7.3')

xbaseline = load('H:\Projects\7TBrainMech\scripts\eeg\Shane\AudSteadyState\XmatrixWithallSubjects_baseline_20Hz_20230206.mat');
xbaseline = xbaseline.xbaseline;

% The x varibale has every subjects data for all channels across all trials 
SDtrials_allsubjects = cell(1,numSubj);

clear channel
for isub = 1:numSubj
    
    if isempty(xbaseline{isub})
        continue
    else

    subjectX = xbaseline{isub};
    
    for c = 1:63
        for t = 1:length(subjectX.trial)
            trial = subjectX.trial{t}; % pulls one trial
            [bandpassedTrial] = ft_preproc_bandpassfilter(trial, 150, [70 30]); % run a bandpass filter over the spontaneous data
            channel(t,:) = bandpassedTrial(c,:); % the time course for channal c during trial t
            
        end
        sd_PerTrial = std(channel,0,2);
        avgAcrossTrialsPerChannel(c,:) = mean(sd_PerTrial);
    end
    
SDtrials_allsubjects{isub} = avgAcrossTrialsPerChannel; 
    end
end

% for isub = 1:numSubj
%     
%     if isempty(xbaseline{isub})
%         continue
%     else
%         
%        sdSubject =  SDtrials_allsubjects{isub};
%        avgSubject = mean(sdSubject, 2); 
%         
%        SpontaneousActivity{isub} = avgSubject; 
%     end 
% end
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubject_SpontaneousBandpassed_40hz_AdditionalSubjects_20230206.mat'), 'SDtrials_allsubjects')


%% Extract info and put into a table
Subjects = load(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubjects_20230208.mat'));
Subjects = Subjects.Subjects;

AmplutideT = table('Size', [0, 4], 'VariableTypes', {'string', 'double', 'double', 'double'});
AmplutideT.Properties.VariableNames = {'Subject', 'Channel', 'Amplitude', 'Spontaneous'};


for isub = 1:numSubj
    
    if isempty(meanSquaredERPpower{isub})
        continue
    else
    
   T = table('Size', [63, 4], 'VariableTypes', {'string', 'double', 'double', 'double'});
   T.Properties.VariableNames = {'Subject', 'Channel', 'Amplitude', 'Spontaneous'};


    subjectsAmps = meanSquaredERPpower{isub};
    subject = Subjects(isub); 
    
    T.Subject(1:63) = subject{1};
    T.Amplitude = subjectsAmps; 
    T.Channel  = data.label;
    T.Spontaneous =  SDtrials_allsubjects{isub}; 
    
    AmplutideT = [AmplutideT;T];
    end
    
end

writetable(AmplutideT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/AuditorySS/AudSS_EvokedSpontaneousActivity_method3_20hzBandpassed_20230206.csv'));








