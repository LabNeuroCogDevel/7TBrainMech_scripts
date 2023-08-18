
%% For Terminal: addpath(('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/'))
%if class labels doesnt work:

addpath(('/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/'))
addpath(genpath('Functions'));
addpath(hera('/Projects/7TBrainMech/scripts/fieldtrip-20220104'))
ft_defaults

datapath = hera('/Projects/7TBrainMech/scripts/eeg/Shane/Prep/AfterWhole/ICAwholeClean_homogenize');

%load in all the delay files
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
classLabels = cell(1,numSubj);

% check to see if subject has already been run
[num,txt,raw] = xlsread(hera('/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_allVariables.csv'));
alreadyRun = txt(:,1);
save(hera('/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/alreadyRun.mat'), 'alreadyRun')

%for terminal:
% load(hera('/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/alreadyRun.mat'))



%% Create X matrix for Spectral Event Toolbox
clear x
clear Subjects

for i = 1:numSubj
    inputfile = setfiles{i};
    subject = inputfile(84:97);
    
    %     if any(strcmp(alreadyRun, subject))
    %         warning('%s already complete', subject)
    %         continue
    %
    %     else
    
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
    cfg.channel =   {'all', '-POz'};
    cfg.trialdef.eventtype = 'trigger';
    cfg.trialdef.eventvalue = '4';
    cfg.trialdef.prestim = 0;
    cfg.trialdef.poststim = 6;
    cfg.trialfun = 'ft_trialfun_general';
    cfg.trialdef.ntrials = 95;
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
    
    
    %redefine the trails to be between 3-4 seconds of the delay period
    cfg.trl = [];
    cfg = rmfield(cfg, 'trl');
    cfg.toilim = [5 6];
    data = ft_redefinetrial(cfg, data);
            
    for j = 1:length(data.trial) %trial
        
        trialData = (data.trial{1,j});
        ChannelTrialData{j} = trialData(:,:);
        
    end
    
%     avgData = squeeze(mean(allData, 1));
    
    x{i} = ChannelTrialData;
end
 save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/IndividualChannelsXmatrix_Delay_5_6.mat'), 'x',  '-v7.3')
 save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/cfg_Delay_5_6.mat'), 'cfg',  '-v7.3')

%% for terminal     
x = load(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/IndividualChannelsXmatrix_Delay_5_6.mat'));
cfg = load(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/cfg_Delay_5_6.mat'));

cfg = cfg.cfg;
x = x.x; %when you load, it loads as a struct. Needs to be cells
%% Gamma Analysis 

eventBand = [30,75]; %Frequency range of spectral events
fVec = (30:75); %Vector of fequency values over which to calculate TFR
Fs = 150; %Sampling rate of time-series
findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
vis = false; %Generate standard visualization plots for event features across all subjects/sessions
%tVec = (1/Fs:1/Fs:1);
% 
% %remove emptry cells (from subjects that had already been run)
% x = x(~cellfun('isempty',x));
% Subjects = Subjects(~cellfun('isempty',Subjects));
%% this is to run the spectral event analysis on every individual channel (method 2)
for c = 1:63 %channels
    for s = 1:length(x)%subject
        clear oneChannel_allTrials
        for t = 1:length(x{1,s})  %trials
            
        oneChannel_allTrials(t,:) =  x{1,s}{1,t}(c,:); %subject s, trial t, channel c
        classLabels{s} = 4+zeros(1,length(x{1,s}) ); %needs to be the same length as the trial number 

        end
        
        oneChannel_allSubjects{s} = oneChannel_allTrials';

    end
        [specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  oneChannel_allSubjects ,classLabels);
        spevEV_struct_allChannels{c} = specEv_struct; 
        TFRs_allChannels{c} = TFRs; 
        X_allChannels{c} = X; 
        
        %save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_specEV_allChannels.mat'), 'spevEV_struct_allChannels','-v7.3')
        fprintf('c = %.0f', c); 
end

%% Gamma
%note this is all delay period 3-4 seconds
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Gamma\Gamma_specEV_allChannels_FIX.mat')
specEV_struct_allChannels = spevEV_struct_allChannels;
 
GammaT = table('Size', [0, 6], 'VariableTypes', {'string', 'double','double', 'double','double','double'});
    GammaT.Properties.VariableNames = {'Subject','Channel', 'Trial' ,'Gamma_Trial_Power','Gamma_Event_Number','Gamma_Event_Duration'};
    
for j = 1:length(specEV_struct_allChannels)
    specEv_struct = specEV_struct_allChannels{1,j};
    
    EventNumber = cell(1, length(specEv_struct));
    EventDuration = cell(1, length(specEv_struct));
    Power = cell(1, length(specEv_struct));
    EventMaxPower = cell(1, length(specEv_struct));
    EventMaxFreq = cell(1, length(specEv_struct));
    
    
    
    for i = 1:length(specEv_struct)
        
        subject = specEv_struct(i);
        if isempty(subject.TrialSummary)
            continue
        end
        
        EventNumber{1,i} = subject.TrialSummary.TrialSummary.eventnumber;
        EventDuration{1,i} = subject.TrialSummary.TrialSummary.meaneventduration;
        Power{1,i} = subject.TrialSummary.TrialSummary.meaneventpower;
        EventMaxPower{1,i} = subject.Events.Events.maximapower;
        EventMaxFreq{1,i} = subject.Events.Events.maximafreq;
        
        
    end
    
    
    for i = 1:length(specEv_struct)
        
        AvgPower_PerSubject(1,i) = mean(Power{1,i});
        AvgEventNumber_PerSubject(1,i) = mean(EventNumber{1,i});
        AvgEventDuration_PerSubject(1,i) = mean(EventDuration{1,i});
        AvgEventMaxPower_PerSubject(1,i) = mean(EventMaxPower{1,i});
        AvgEventMaxFreq_PerSubject(1,i) = mean(EventMaxFreq{1,i});
        SDPower_PerSubject(1,i) = std(Power{1,i});
        
    end
    
    
    
   
    %Extract info trial by trial
    for i = 1:length(specEv_struct) %Subjects
        clear Trial_power
        clear Trial_eventDuration
        clear Trial_eventNumber
        
        T = table('Size', [length(Power{1,i}), 6], 'VariableTypes', {'string', 'double','double', 'double','double','double'});
        T.Properties.VariableNames = {'Subject', 'Channel', 'Trial' ,'Gamma_Trial_Power','Gamma_Event_Number','Gamma_Event_Duration'};
        
        if isempty(Power{1,i}) || isempty(EventNumber{1,i}) || isempty(EventDuration{1,i})
            continue
        end
        
        
        %         for k = 1: length(Power{1,i}) %Trials
        Subject_power = Power{1,i};
        %             Trial_power(i,k) = Subject_power(k,1);
        %         end
        
        %         for k = 1:length(EventNumber{1,i})
        Subject_channel_eventNumber = EventNumber{1,i};
        %             Trial_eventNumber(i,k) = Subject_channel_eventNumber(k,1);
        %         end
        %
        %         for k = 1:length(EventDuration{1,i})
        Subject_channel_eventDuration= EventDuration{1,i};
        %             Trial_eventDuration(i,k) = Subject_channel_eventDuration(k,1);
        %         end
        
        
        if isempty(Power{1,i}) || isempty(EventNumber{1,i}) || isempty(EventDuration{1,i})
            continue
        end
        
        
        T.Gamma_Trial_Power = Subject_power;
        T.Gamma_Event_Number = Subject_channel_eventNumber;
        T.Gamma_Event_Duration = Subject_channel_eventDuration;
        T.Trial = [1:length(T.Gamma_Trial_Power)]';
        T.Subject(1:length(T.Gamma_Trial_Power)) = idvalues(i,:);
        T.Channel = j+zeros(size(Subject_power,1),1); 
        GammaT = [GammaT; T];
        
        
    end
end
writetable(GammaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_allChannels_TrialLevel_FIX.csv'));


%%
% group by region and then run spectral event toolbox 
frontalChannels_indx = find(contains(data.elec.label, ["F3","F4", "F1", "F2", "F5", "F6", "F7", "F8", "Fz"]));
occipitalChannels_indx = find(contains(data.elec.label, 'O'));
parietalChannels_indx = find(contains(data.elec.label, 'P'));
dlpfcChannels_indx = find(contains(data.elec.label, ["F3","F4"]));

clear newX
clear frontal_trialLevel
frontal_trialLevel = [];
occipital_trialLevel = [];
parietal_trialLevel = [];
dlpfc_trialLevel = [];

for i = 1:length(x)

    for j = 1:length(x{1, i})
        subjectData_trialLevel = x{1, i}{1,j};
        dlpfcChannels_trialLevel = subjectData_trialLevel(dlpfcChannels_indx,:);
        avg_dlpfcChannels_trialLevel = mean(dlpfcChannels_trialLevel);
        
        dlpfc_trialLevel(j,:) = avg_dlpfcChannels_trialLevel;
        
    end
    
    newX{i} = dlpfc_trialLevel';
    
end

for i = 1:length(newX)
    classLabels{i} = 4+zeros(1,size(newX{i},2));
end

[specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  newX ,classLabels);

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Delay5_6/Gamma_specEV_DLPFC_Delay_5_6.mat'), 'specEv_struct', '-v7.3')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Delay5_6/Gamma_TFRs_DLPFC_Delay_5_6.mat'), 'TFRs', '-v7.3')


%% Theta Analysis
eventBand = [4,7]; %Frequency range of spectral events
fVec = (1:30); %Vector of fequency values over which to calculate TFR
Fs = 150; %Sampling rate of time-series
findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
vis = false; %Generate standard visualization plots for event features across all subjects/sessions
%tVec = (1/Fs:1/Fs:1);
%             classLabels = 4+zeros(1,size(avgData,1));

%remove emptry cells (from subjects that had already been run)
% x = x(~cellfun('isempty',x));
% Subjects = Subjects(~cellfun('isempty',Subjects));

for c = 1:63 %channels
    for s = 1:length(x)%subject
        clear oneChannel_allTrials
        for t = 1:length(x{1,s})  %trials
            
        oneChannel_allTrials(t,:) =  x{1,s}{1,t}(c,:); %subject s, trial t, channel c
        classLabels{s} = 4+zeros(1,length(x{1,s}) ); %needs to be the same length as the trial number 

        end
        
        oneChannel_allSubjects{s} = oneChannel_allTrials';

    end
        [specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  oneChannel_allSubjects ,classLabels);
        spevEV_struct_allChannels{c} = specEv_struct; 
        TFRs_allChannels{c} = TFRs; 
        X_allChannels{c} = X; 
        
        %save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_specEV_allChannels.mat'), 'spevEV_struct_allChannels','-v7.3')
        fprintf('c = %.0f', c); 
end

% group by region and then run spectral event toolbox 
%frontal
frontalChannels_indx = find(contains(data.elec.label, ["F3","F4", "F1", "F2", "F5", "F6", "F7", "F8", "Fz"]));

for i = 1:length(x)
%     clear frontal_trialLevel

    
    for j = 1:length(x{1, i})
        subjectData_trialLevel = x{1, i}{1,j};
        frontalChannels_trialLevel = subjectData_trialLevel(frontalChannels_indx,:);
        avg_frontalChannels_trialLevel = mean(frontalChannels_trialLevel);
        
        frontal_trialLevel(j,:) = avg_frontalChannels_trialLevel;
        
    end
    
    newX{i} = frontal_trialLevel';
    
end

for i = 1:length(newX)
    classLabels{i} = 4+zeros(1,size(newX{i},2));
end

[specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  newX ,classLabels);


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_specEV_selectiveFrontal_Delay_5_6.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_TFRs_selectiveFrontal_Delay_5_6.mat'), 'TFRs')


% occipital 
occipitalChannels_indx = find(contains(data.elec.label, 'O'));
parietalChannels_indx = find(contains(data.elec.label, 'P'));
dlpfcChannels_indx = find(contains(data.elec.label, ["F3","F4"]));

clear newX

for i = 1:length(x)
%     clear frontal_trialLevel

    
    for j = 1:length(x{1, i})
        subjectData_trialLevel = x{1, i}{1,j};
        occipitalChannels_trialLevel = subjectData_trialLevel(occipitalChannels_indx,:);
        avg_occipitalChannels_trialLevel = mean(occipitalChannels_trialLevel);
        
        occipital_trialLevel(j,:) = avg_occipitalChannels_trialLevel;
        
    end
    
    newX{i} = occipital_trialLevel';
    
end

for i = 1:length(newX)
    classLabels{i} = 4+zeros(1,size(newX{i},2));
end

[specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  newX ,classLabels);


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_specEV_Occipital_Delay_5_6.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_TFRs_Occipital_Delay_5_6.mat'), 'TFRs')

%Parietal 
parietalChannels_indx = find(contains(data.elec.label, 'P'));
dlpfcChannels_indx = find(contains(data.elec.label, ["F3","F4"]));

clear newX

for i = 1:length(x)
%     clear frontal_trialLevel

    
    for j = 1:length(x{1, i})
        subjectData_trialLevel = x{1, i}{1,j};
        parietalChannels_trialLevel = subjectData_trialLevel(parietalChannels_indx,:);
        avg_parietalChannels_trialLevel = mean(parietalChannels_trialLevel);
        
        parietal_trialLevel(j,:) = avg_parietalChannels_trialLevel;
        
    end
    
    newX{i} = parietal_trialLevel';
    
end

for i = 1:length(newX)
    classLabels{i} = 4+zeros(1,size(newX{i},2));
end

[specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  newX ,classLabels);


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_specEV_Parietal_Delay_5_6.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_TFRs_Parietal_Delay_5_6.mat'), 'TFRs')

%DLPFC
dlpfcChannels_indx = find(contains(data.elec.label, ["F3","F4"]));

clear newX

for i = 1:length(x)
%     clear frontal_trialLevel

    
    for j = 1:length(x{1, i})
        subjectData_trialLevel = x{1, i}{1,j};
        dlpfcChannels_trialLevel = subjectData_trialLevel(dlpfcChannels_indx,:);
        avg_dlpfcChannels_trialLevel = mean(dlpfcChannels_trialLevel);
        
        dlpfc_trialLevel(j,:) = avg_dlpfcChannels_trialLevel;
        
    end
    
    newX{i} = dlpfc_trialLevel';
    
end

for i = 1:length(newX)
    classLabels{i} = 4+zeros(1,size(newX{i},2));
end

[specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  newX ,classLabels);


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_specEV_DLPFC_Delay_5_6.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_TFRs_DLPFC_Delay_5_6.mat'), 'TFRs')


%% Beta Analysis
eventBand = [13,30]; %Frequency range of spectral events
fVec = (1:30); %Vector of fequency values over which to calculate TFR
Fs = 150; %Sampling rate of time-series
findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
vis = false; %Generate standard visualization plots for event features across all subjects/sessions
%tVec = (1/Fs:1/Fs:1);
%             classLabels = 4+zeros(1,size(avgData,1));

for c = 1:63 %channels
    for s = 1:length(x)%subject
        clear oneChannel_allTrials
        for t = 1:length(x{1,s})  %trials
            
        oneChannel_allTrials(t,:) =  x{1,s}{1,t}(c,:); %subject s, trial t, channel c
        classLabels{s} = 4+zeros(1,length(x{1,s}) ); %needs to be the same length as the trial number 

        end
        
        oneChannel_allSubjects{s} = oneChannel_allTrials';

    end
        [specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  oneChannel_allSubjects ,classLabels);
        spevEV_struct_allChannels{c} = specEv_struct; 
        TFRs_allChannels{c} = TFRs; 
        X_allChannels{c} = X; 
        
        %save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_specEV_allChannels.mat'), 'spevEV_struct_allChannels','-v7.3')
        fprintf('c = %.0f', c); 
end


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_specEV_allChannels_Delay3_4.mat'), 'spevEV_struct_allChannels','-v7.3')


% group by region and then run spectral event toolbox 
%frontal
frontalChannels_indx = find(contains(data.elec.label, ["F3","F4", "F1", "F2", "F5", "F6", "F7", "F8", "Fz"]));

for i = 1:length(x)
%     clear frontal_trialLevel

    
    for j = 1:length(x{1, i})
        subjectData_trialLevel = x{1, i}{1,j};
        frontalChannels_trialLevel = subjectData_trialLevel(frontalChannels_indx,:);
        avg_frontalChannels_trialLevel = mean(frontalChannels_trialLevel);
        
        frontal_trialLevel(j,:) = avg_frontalChannels_trialLevel;
        
    end
    
    newX{i} = frontal_trialLevel';
    
end

for i = 1:length(newX)
    classLabels{i} = 4+zeros(1,size(newX{i},2));
end

[specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  newX ,classLabels);


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_specEV_selectiveFrontal_Delay_5_6.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_TFRs_selectiveFrontal_Delay_5_6.mat'), 'TFRs')


% occipital 
occipitalChannels_indx = find(contains(data.elec.label, 'O'));
parietalChannels_indx = find(contains(data.elec.label, 'P'));
dlpfcChannels_indx = find(contains(data.elec.label, ["F3","F4"]));

clear newX

for i = 1:length(x)
%     clear frontal_trialLevel

    
    for j = 1:length(x{1, i})
        subjectData_trialLevel = x{1, i}{1,j};
        occipitalChannels_trialLevel = subjectData_trialLevel(occipitalChannels_indx,:);
        avg_occipitalChannels_trialLevel = mean(occipitalChannels_trialLevel);
        
        occipital_trialLevel(j,:) = avg_occipitalChannels_trialLevel;
        
    end
    
    newX{i} = occipital_trialLevel';
    
end

for i = 1:length(newX)
    classLabels{i} = 4+zeros(1,size(newX{i},2));
end

[specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  newX ,classLabels);


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_specEV_Occipital_Delay_5_6.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_TFRs_Occipital_Delay_5_6.mat'), 'TFRs')

%Parietal 
parietalChannels_indx = find(contains(data.elec.label, 'P'));
dlpfcChannels_indx = find(contains(data.elec.label, ["F3","F4"]));

clear newX

for i = 1:length(x)
%     clear frontal_trialLevel

    
    for j = 1:length(x{1, i})
        subjectData_trialLevel = x{1, i}{1,j};
        parietalChannels_trialLevel = subjectData_trialLevel(parietalChannels_indx,:);
        avg_parietalChannels_trialLevel = mean(parietalChannels_trialLevel);
        
        parietal_trialLevel(j,:) = avg_parietalChannels_trialLevel;
        
    end
    
    newX{i} = parietal_trialLevel';
    
end

for i = 1:length(newX)
    classLabels{i} = 4+zeros(1,size(newX{i},2));
end

[specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  newX ,classLabels);


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_specEV_Parietal_Delay_5_6.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_TFRs_Parietal_Delay_5_6.mat'), 'TFRs')

%DLPFC
dlpfcChannels_indx = find(contains(data.elec.label, ["F3","F4"]));

clear newX

for i = 1:length(x)
%     clear frontal_trialLevel

    
    for j = 1:length(x{1, i})
        subjectData_trialLevel = x{1, i}{1,j};
        dlpfcChannels_trialLevel = subjectData_trialLevel(dlpfcChannels_indx,:);
        avg_dlpfcChannels_trialLevel = mean(dlpfcChannels_trialLevel);
        
        dlpfc_trialLevel(j,:) = avg_dlpfcChannels_trialLevel;
        
    end
    
    newX{i} = dlpfc_trialLevel';
    
end

for i = 1:length(newX)
    classLabels{i} = 4+zeros(1,size(newX{i},2));
end

[specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  newX ,classLabels);


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_specEV_DLPFC_Delay_5_6.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_TFRs_DLPFC_Delay_5_6.mat'), 'TFRs')


%% Alpha Analysis
eventBand = [8,12]; %Frequency range of spectral events
fVec = (1:30); %Vector of fequency values over which to calculate TFR
Fs = 150; %Sampling rate of time-series
findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
vis = false; %Generate standard visualization plots for event features across all subjects/sessions
%tVec = (1/Fs:1/Fs:1);
%         classLabels = 4+zeros(1,size(avgData,1));

for c = 1:63 %channels
    for s = 1:length(x)%subject
        clear oneChannel_allTrials
        for t = 1:length(x{1,s})  %trials
            
        oneChannel_allTrials(t,:) =  x{1,s}{1,t}(c,:); %subject s, trial t, channel c
        classLabels{s} = 4+zeros(1,length(x{1,s}) ); %needs to be the same length as the trial number 

        end
        
        oneChannel_allSubjects{s} = oneChannel_allTrials';

    end
        [specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  oneChannel_allSubjects ,classLabels);
        spevEV_struct_allChannels{c} = specEv_struct; 
        TFRs_allChannels{c} = TFRs; 
        X_allChannels{c} = X; 
        
        save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_specEV_allChannels.mat'), 'spevEV_struct_allChannels','-v7.3')
        fprintf('c = %.0f', c); 
end


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Delay5_6/Alpha_SpecEvents_newSubs_5_6.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Delay5_6/Alpha_TFR_newSubs_5_6.mat'), 'TFRs')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Delay5_6/Alpha_newSubs_5_6.mat'), 'Subjects')



% group by region and then run spectral event toolbox 
%frontal
frontalChannels_indx = find(contains(data.elec.label, ["F3","F4", "F1", "F2", "F5", "F6", "F7", "F8", "Fz"]));

clear newX

clear frontal_trialLevel

for i = 1:length(x)
%     clear frontal_trialLevel

    
    for j = 1:length(x{1, i})
        subjectData_trialLevel = x{1, i}{1,j};
        frontalChannels_trialLevel = subjectData_trialLevel(frontalChannels_indx,:);
        avg_frontalChannels_trialLevel = mean(frontalChannels_trialLevel);
        
        frontal_trialLevel(j,:) = avg_frontalChannels_trialLevel;
        
    end
    
    newX{i} = frontal_trialLevel';
    
end

for i = 1:length(newX)
    classLabels{i} = 4+zeros(1,size(newX{i},2));
end

[specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  newX ,classLabels);


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_specEV_selectiveFrontal_Delay_5_6.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_TFRs_selectiveFrontal_Delay_5_6.mat'), 'TFRs')


% occipital 
occipitalChannels_indx = find(contains(data.elec.label, 'O'));
parietalChannels_indx = find(contains(data.elec.label, 'P'));
dlpfcChannels_indx = find(contains(data.elec.label, ["F3","F4"]));

clear newX

for i = 1:length(x)
%     clear frontal_trialLevel

    
    for j = 1:length(x{1, i})
        subjectData_trialLevel = x{1, i}{1,j};
        occipitalChannels_trialLevel = subjectData_trialLevel(occipitalChannels_indx,:);
        avg_occipitalChannels_trialLevel = mean(occipitalChannels_trialLevel);
        
        occipital_trialLevel(j,:) = avg_occipitalChannels_trialLevel;
        
    end
    
    newX{i} = occipital_trialLevel';
    
end

for i = 1:length(newX)
    classLabels{i} = 4+zeros(1,size(newX{i},2));
end

[specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  newX ,classLabels);


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_specEV_Occipital_Delay_5_6.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_TFRs_Occipital_Delay_5_6.mat'), 'TFRs')

%Parietal 
parietalChannels_indx = find(contains(data.elec.label, 'P'));
dlpfcChannels_indx = find(contains(data.elec.label, ["F3","F4"]));

clear newX

for i = 1:length(x)
%     clear frontal_trialLevel

    
    for j = 1:length(x{1, i})
        subjectData_trialLevel = x{1, i}{1,j};
        parietalChannels_trialLevel = subjectData_trialLevel(parietalChannels_indx,:);
        avg_parietalChannels_trialLevel = mean(parietalChannels_trialLevel);
        
        parietal_trialLevel(j,:) = avg_parietalChannels_trialLevel;
        
    end
    
    newX{i} = parietal_trialLevel';
    
end

for i = 1:length(newX)
    classLabels{i} = 4+zeros(1,size(newX{i},2));
end

[specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  newX ,classLabels);


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_specEV_Parietal_Delay_5_6.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_TFRs_Parietal_Delay_5_6.mat'), 'TFRs')

%DLPFC
dlpfcChannels_indx = find(contains(data.elec.label, ["F3","F4"]));

clear newX

for i = 1:length(x)
%     clear frontal_trialLevel

    
    for j = 1:length(x{1, i})
        subjectData_trialLevel = x{1, i}{1,j};
        dlpfcChannels_trialLevel = subjectData_trialLevel(dlpfcChannels_indx,:);
        avg_dlpfcChannels_trialLevel = mean(dlpfcChannels_trialLevel);
        
        dlpfc_trialLevel(j,:) = avg_dlpfcChannels_trialLevel;
        
    end
    
    newX{i} = dlpfc_trialLevel';
    
end

for i = 1:length(newX)
    classLabels{i} = 4+zeros(1,size(newX{i},2));
end

[specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  newX ,classLabels);


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_specEV_DLPFC_Delay_5_6.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_TFRs_DLPFC_Delay_5_6.mat'), 'TFRs')
