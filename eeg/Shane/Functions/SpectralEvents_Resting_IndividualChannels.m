
%% For Terminal: addpath(('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/'))
%if class labels doesnt work:

addpath(('/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/'))
addpath(genpath('Functions'));
addpath(hera('/Projects/7TBrainMech/scripts/fieldtrip-20191127'))
ft_defaults

datapath = hera('/Projects/7TBrainMech/scripts/eeg/Shane/Resting_State/AfterWhole/ICAwholeClean_homogenize');

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
    Subjects{:,i} = inputfile(93:106);
    
    
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
    cfg.channel =   {'all', '-POz'};
    cfg.trialdef.eventtype = 'trigger';
     cfg.trialdef.eventvalue = '16129';
    cfg.trialdef.prestim = 0;
    cfg.trialdef.poststim = 4;
    cfg.trialfun = 'ft_trialfun_general';
    cfg.trialdef.ntrials = 57;
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
    
    
    %redefine the trails to be between 2 and 3 of the eyes open resting
    %state period 
    cfg.trl = [];
    cfg = rmfield(cfg, 'trl');
    cfg.toilim = [2 3];
    data = ft_redefinetrial(cfg, data);
            
    for j = 1:length(data.trial) %trial
        
        trialData = (data.trial{1,j});
        ChannelTrialData{j} = trialData(:,:);
        
    end
    
%     avgData = squeeze(mean(allData, 1));
    
    x{i} = ChannelTrialData;
end

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/cfg_RestingState_IndividualTrial.mat'), 'cfg')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/IndividualChannelsXmatrix_RestingState.mat'), 'x')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Subjects_RestingState.mat'), 'Subjects')


%% for terminal     
x = load(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/IndividualChannelsXmatrix_RestingState.mat'));

cfg = load(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/cfg_RestingState_IndividualTrial.mat'));

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
x = x(~cellfun('isempty',x));
Subjects = Subjects(~cellfun('isempty',Subjects));

%% group by region and then run spectral event toolbox 
%frontal
frontalChannels_indx =find(contains(data.elec.label, 'F'));

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_specEV_Frontal_RS.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_TFRs_Frontal_RS.mat'), 'TFRs')


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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_specEV_Occipital_RS.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_TFRs_Occipital_RS.mat'), 'TFRs')

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_specEV_Parietal_RS.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_TFRs_Parietal_RS.mat'), 'TFRs')

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_specEV_DLPFC_RS.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_TFRs_DLPFC_RS.mat'), 'TFRs')


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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_specEV_Frontal_RS.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_TFRs_Frontal_RS.mat'), 'TFRs')


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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_specEV_Occipital_RS.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_TFRs_Occipital_RS.mat'), 'TFRs')

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_specEV_Parietal_RS.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_TFRs_Parietal_RS.mat'), 'TFRs')

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_specEV_DLPFC_RS.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_TFRs_DLPFC_RS.mat'), 'TFRs')



%% Beta Analysis
eventBand = [13,30]; %Frequency range of spectral events
fVec = (1:30); %Vector of fequency values over which to calculate TFR
Fs = 150; %Sampling rate of time-series
findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
vis = false; %Generate standard visualization plots for event features across all subjects/sessions
%tVec = (1/Fs:1/Fs:1);
%             classLabels = 4+zeros(1,size(avgData,1));



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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_specEV_Frontal_RS.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_TFRs_Frontal_RS.mat'), 'TFRs')


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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_specEV_Occipital_RS.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_TFRs_Occipital_RS.mat'), 'TFRs')

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_specEV_Parietal_RS.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_TFRs_Parietal_RS.mat'), 'TFRs')

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_specEV_DLPFC_RS.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_TFRs_DLPFC_RS.mat'), 'TFRs')


%% Alpha Analysis
eventBand = [8,12]; %Frequency range of spectral events
fVec = (1:30); %Vector of fequency values over which to calculate TFR
Fs = 150; %Sampling rate of time-series
findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
vis = false; %Generate standard visualization plots for event features across all subjects/sessions
%tVec = (1/Fs:1/Fs:1);
%         classLabels = 4+zeros(1,size(avgData,1));

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_specEV_Frontal_RS.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_TFRs_Frontal_RS.mat'), 'TFRs')


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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_specEV_Occipital_RS.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_TFRs_Occipital_RS.mat'), 'TFRs')

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_specEV_Parietal_RS.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_TFRs_Parietal_RS.mat'), 'TFRs')

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_specEV_DLPFC_RS.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_TFRs_DLPFC_RS.mat'), 'TFRs')

