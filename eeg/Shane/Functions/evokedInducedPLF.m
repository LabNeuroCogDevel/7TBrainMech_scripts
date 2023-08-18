
% Auditory Steady State
%% Evoked Activity
addpath(genpath('Functions'));
addpath(genpath(hera('/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/')))
addpath(hera('/Projects/7TBrainMech/scripts/fieldtrip-20191213'))
ft_defaults

addpath(genpath(hera('/Projects/7TBrainMech/scripts/eeg/Shane/resources/eeglab2022.1')))
eeglab

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


clear x
clear Subjects

% Creat x matrix not baselined
for i = 1:numSubj
    inputfile = setfiles{i};
    subject = inputfile(105:118);

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
    cfg.trialdef.eventvalue = '4'; % take only the sections with trigger value 4 (40 hz), 3 (30 hz), or 2 (20 hz)
    cfg.trialdef.prestim = 0.2;
    cfg.trialdef.poststim = .5;
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

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/XmatrixWithallSubjects_40hz_includesBaseline_20230818.mat'), 'x', '-v7.3')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/AllSubjects_20230818.mat'), 'Subjects', '-v7.3')

x = load(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/XmatrixWithallSubjects_40hz_20230818.mat'));
x = x.x;

% cap locations
eeglabpath = fileparts(which('eeglab'));

cap_location = hera('/Projects/7TBrainMech/scripts/fieldtrip-20191213/template/layout/biosemi64.lay');
if ~exist(cap_location, 'file'), error('cannot find file for 128 channel cap: %s', cap_location), end

cfg = [];
cfg.layout = cap_location;
% find average data per channel

for i = 1:numSubj
    if isempty(x{i})
        continue
    else

        cfg.keepindividual = 'no';  % Set to 'yes' if you want to keep individual trials in the output
        average_data = ft_timelockanalysis(cfg, x{i});

        allSubjectAvgData{i} = average_data;

    end
end

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubject_40Hz_averagedTrials_allChannels_includesBaseline_20230818.mat'), 'allSubjectAvgData')

allSubjectAvgData = load(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubject_40Hz_averagedTrials_allChannels_20230818.mat'));
allSubjectAvgData = allSubjectAvgData.allSubjectAvgData;

%% Evoked Power
%define the time points where you want to average the amplitude in between
% (here we are going to find the mean amplitude of the wavelet transformation between 50 - 500ms

allSubjectpower = cell(1,numSubj);

for isub = 1:numSubj
    if isempty(allSubjectAvgData{isub})
        continue
    else

        cfg = [];
        cfg.channel    = {'F3', 'F5', 'F7','F4','F6','F8'};
        cfg.method     = 'wavelet';
        cfg.width      = 3;
        cfg.output     = 'pow';
        cfg.foi        = 10:1:70;
        cfg.toi        = -0.2:0.01:0.5; % select for -20-500ms after the stimuli


        TFRwave2 = ft_freqanalysis(cfg, allSubjectAvgData{isub});% creates channel x freq x time point struct


        % avgPower = mean(TFRwave.powspctrm,3); %average power across time
        % avgPowerPerChan = mean(avgPower,2); %avg power values for all 41 points of frequency evaluated between 30 and 70 Hz
        % 
        % 
        % allSubjectEvokedPower{isub} = avgPowerPerChan; % the mean ERP power per channel
        % meanSquaredEvokedPower{isub} = avgPowerPerChan.^2; % mean squared power for each channel

evokedPowerDLPFCs{isub} = TFRwave;

    end
end

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubject_MeanSquaredPower_40hz_20230707.mat'), 'meanSquaredEvokedPower')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubject_evokedPower_40hz_20230707.mat'), 'allSubjectEvokedPower')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubject_evokedPower_DLPFCs_40hz_includesBaseline_20230707.mat'), 'evokedPowerDLPFCs')

evokedActivity = load(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubject_evokedPower_40hz_20230707.mat'));
evokedActivity = evokedActivity.allSubjectEvokedPower;

evokedActivity_DLPFCs = load(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubject_evokedPower_DLPFCs_40hz_20230707.mat'));
evokedActivity_DLPFCs = evokedActivity_DLPFCs.evokedPowerDLPFCs;

%% Evoked Power Baseline Corrected
% define the time points where you want to average the amplitude in between
% (here we are going to find the mean amplitude of the wavelet transformation between 50 - 500ms

allSubjectpower = cell(1,numSubj);

for isub = 1:numSubj
    if isempty(allSubjectAvgData{isub})
        continue
    else

        cfg = [];
        cfg.channel    = {'F3', 'F5', 'F7', 'F4', 'F6', 'F8'};
        cfg.method     = 'wavelet';
        cfg.width      = 2;
        cfg.output     = 'pow';
        cfg.foi        = 10:1:70;
        cfg.toi        = 0:0.01:0.5; % select for 50-500ms after the stimuli
        cfg.baseline = [-0.2 0];
        cfg.baselinetype = 'db';

        TFRwave = ft_freqanalysis(cfg, allSubjectAvgData{isub});% creates channel x freq x time point struct


        % avgPower = mean3TFRwave.powspctrm,3); %average power across time
        % avgPowerPerChan = mean(avgPower,2); %avg power values for all 41 points of frequency evaluated between 30 and 70 Hz
        % 
        % 
        % allSubjectEvokedPower{isub} = avgPowerPerChan; % the mean ERP power per channel
        % meanSquaredEvokedPower{isub} = avgPowerPerChan.^2; % mean squared power for each channel

evokedPowerDLPFCs{isub} = TFRwave;

    end
end

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubject_MeanSquaredPower_40hz_20230707.mat'), 'meanSquaredEvokedPower')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubject_evokedPower_40hz_20230707.mat'), 'allSubjectEvokedPower')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubject_evokedPowerBaselined_DLPFCs_40hz_20230707.mat'), 'evokedPowerDLPFCs')

evokedActivity = load(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubject_evokedPower_40hz_20230707.mat'));
evokedActivity = evokedActivity.allSubjectEvokedPower;

evokedActivity_DLPFCs = load(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubject_evokedPower_DLPFCs_40hz_20230707.mat'));
evokedActivity_DLPFCs = evokedActivity_DLPFCs.evokedPowerDLPFCs;


%% Induced Activity
for isub = 1:numSubj

    if isempty(x{isub})
        continue
    else

        subjectX = x{isub};

        % Get the number of trials and channels
        num_trials = length(subjectX.trial);
        num_channels = 6;
        channels = [4,5,6,36,37,38];

        % Create a cell array to store the individual EEG structures
        eeg_structs = cell(num_trials, num_channels);

        % Loop over trials and channels
        for trial = 1:num_trials
            for i = 1:num_channels
                channel = channels(i);

                % Extract the data for the current trial and channel
                trial_data = subjectX.trial{trial};
                channel_data = trial_data(channel, :);
                time_data = subjectX.time{trial};

                % Create a new FieldTrip structure for the current trial and channel
                eeg_struct = struct();
                eeg_struct.label = {subjectX.label{channel}};
                eeg_struct.fsample = subjectX.fsample;
                eeg_struct.time = {time_data};
                eeg_struct.trial = {channel_data};

                % Store the EEG structure in the cell array
                eeg_structs{trial, i} = eeg_struct; %creates a trial x channel cell array with an EEG struct that can be fed into ft_freqanalysis for each channel for each trial
            end
        end


        % Configure the time-frequency analysis
        cfg = [];
        cfg.channel    = 'EEG';
        cfg.method     = 'wavelet';
        cfg.width      = 3;
        cfg.output     = 'pow';
        cfg.foi        = 30:1:70;
        cfg.toi        = 0.05:0.01:0.5; % select for 50-500ms after the stimuli

        % Initialize a cell array to store the time-frequency results for each trial and channel

        % Loop over trials and channels
        for channel = 1:size(eeg_structs, 2)
            parfor trial = 1:size(eeg_structs, 1)
                % Get the EEG structure for the current trial and channel
                eeg_struct = eeg_structs{trial, channel};

                % Perform the time-frequency analysis using ft_freqanalysis
                freq_data = ft_freqanalysis(cfg, eeg_struct);

                % Store the time-frequency results in the cell array
                tf_results(:,:,trial) = squeeze(freq_data.powspctrm);
            end

            avgTrials_inducedActivity{channel} = mean(tf_results,3);

        end


        inducedActivity{isub} = avgTrials_inducedActivity;

    end

end

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubject_inducedActivity_40hz_20230712.mat'), 'inducedActivity')

inducedActivity = load(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/allSubject_inducedActivity_40hz_20230712.mat'));
inducedActivity = inducedActivity.inducedActivity;










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








