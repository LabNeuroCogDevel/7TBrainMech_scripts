%% For Terminal: addpath(('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/'))
%if class labels doesnt work:
addpath(genpath('Functions'));
addpath(genpath(hera('/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/')))
addpath(hera('/Projects/7TBrainMech/scripts/fieldtrip-20191213'))
ft_defaults

datapath = hera('/Projects/7TBrainMech/scripts/eeg/Shane/Prep/AfterWhole/ICAwholeClean_homogenize');

%load in all the Fix files
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

[num,txt,raw] = xlsread(hera('/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_allChannels_TrialLevel_Delay_3_4.xls'));
alreadyRun = txt(:,1);

%for terminal:
% load(hera('/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/alreadyRun.mat'))



%% Create X matrix for Spectral Event Toolbox
clear x
clear Subjects

for i = 1:numSubj
    inputfile = setfiles{i};
    subject = inputfile(95:108);
    
        if any(strcmp(alreadyRun, subject))
            warning('%s already complete', subject)
            continue

        else
        
    clear events
    clear data
    clear hdr
    clear avgData
    clear classLabels
    clear allData
    clear ChannelTrialData

    hdr = ft_read_header(inputfile);
    data = ft_read_data(inputfile, 'header', hdr);
    events = ft_read_event(inputfile, 'header', hdr);

    cfg = [];
    cfg.dataset = inputfile;
    cfg.headerfile = inputfile;
        cfg.channel =   {'all', '-POz', '-EX3', '-EX4'};
    cfg.trialdef.eventtype = 'trigger';
    cfg.trialdef.eventvalue = '2';
    cfg.trialdef.prestim = 0;
    cfg.trialdef.poststim = 1;
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


    %redefine the trails to be between 3-4 seconds of the Fix period
    cfg.trl = [];
    cfg = rmfield(cfg, 'trl');
    cfg.toilim = [0 1];
    data = ft_redefinetrial(cfg, data);

    for j = 1:length(data.trial) %trial

        trialData = (data.trial{1,j});
        ChannelTrialData{j} = trialData(:,:);

    end

%     avgData = squeeze(mean(allData, 1));
    
    x{i} = ChannelTrialData;
    additionalSubject{i} = inputfile(95:108);

        end
end

         
 save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/IndividualChannelsXmatrix_fix_additionalSubjects_20230630.mat'), 'x',  '-v7.3')
 save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/cfg_fix_additionalSubjects_20230630.mat'), 'cfg',  '-v7.3')

 
%% for terminal     
load(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/IndividualChannelsXmatrix_Fix.mat'));
load(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/cfg_Fix.mat'));

cfg = cfg.cfg;
x = x.x; %when you load, it loads as a struct. Needs to be cells
%% Gamma Analysis 

eventBand = [35,65]; %Frequency range of spectral events
fVec = (1:70); %Vector of fequency values over which to calculate TFR
Fs = 150; %Sampling rate of time-series
findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
vis = false; %Generate standard visualization plots for event features across all subjects/sessions
%tVec = (1/Fs:1/Fs:1);
% 

% %remove emptry cells (from subjects that had already been run)
x = x(~cellfun('isempty',x));
SubjectsRan = additionalSubject(~cellfun('isempty',additionalSubject));

%remove emptry cells (from subjects that had already been run)
for c = 1:63 %channels
    for s = 1:length(x)%subject
        for t = 1:length(x{1,s})  %trials
            
        oneChannel_allTrials(t,:) =  x{1,s}{1,t}(c,:); %subject s, trial t, channel c
        classLabels{s} = 2+zeros(1,length(x{1,s}) ); %needs to be the same length as the trial number 

        end
        
        oneChannel_allSubjects{s} = oneChannel_allTrials';
        
     clear oneChannel_allTrials

    end        

        [specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  oneChannel_allSubjects ,classLabels);
        spevEV_struct_allChannels{c} = specEv_struct; 
        TFRs_allChannels{c} = TFRs; 
        X_allChannels{c} = X; 
        
        %save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_specEV_allChannels_FIX.mat'), 'spevEV_struct_allChannels','-v7.3')
        fprintf('c = %.0f', c); 
end

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_TFR_allChannels_FIX.mat'), 'TFRs_allChannels','-v7.3')

%%
% group by region and then run spectral event toolbox 
%frontal
frontalChannels_indx = find(contains(data.elec.label, 'F'));

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_specEV_Frontal_Fix.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_TFRs_Frontal_Fix.mat'), 'TFRs')


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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_specEV_Occipital_Fix.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_TFRs_Occipital_Fix.mat'), 'TFRs')

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_specEV_Parietal_Fix.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_TFRs_Parietal_Fix.mat'), 'TFRs')

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_specEV_DLPFC_Fix.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_TFRs_DLPFC_Fix.mat'), 'TFRs')


%% Theta Analysis
eventBand = [4,7]; %Frequency range of spectral events
fVec = (1:30); %Vector of fequency values over which to calculate TFR
Fs = 150; %Sampling rate of time-series
findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
vis = false; %Generate standard visualization plots for event features across all subjects/sessions
%tVec = (1/Fs:1/Fs:1);
%             classLabels = 4+zeros(1,size(avgData,1));

%% group by region and then run spectral event toolbox 
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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_specEV_Frontal_Fix.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_TFRs_Frontal_Fix.mat'), 'TFRs')


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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_specEV_Occipital_Fix.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_TFRs_Occipital_Fix.mat'), 'TFRs')

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_specEV_Parietal_Fix.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_TFRs_Parietal_Fix.mat'), 'TFRs')

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_specEV_DLPFC_Fix.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_TFRs_DLPFC_Fix.mat'), 'TFRs')



%% Beta Analysis
eventBand = [13,30]; %Frequency range of spectral events
fVec = (1:30); %Vector of fequency values over which to calculate TFR
Fs = 150; %Sampling rate of time-series
findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
vis = false; %Generate standard visualization plots for event features across all subjects/sessions
%tVec = (1/Fs:1/Fs:1);
%             classLabels = 4+zeros(1,size(avgData,1));


%% group by region and then run spectral event toolbox 
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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_specEV_Frontal_Fix.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_TFRs_Frontal_Fix.mat'), 'TFRs')


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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_specEV_Occipital_Fix.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_TFRs_Occipital_Fix.mat'), 'TFRs')

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_specEV_Parietal_Fix.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_TFRs_Parietal_Fix.mat'), 'TFRs')

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_specEV_DLPFC_Fix.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_TFRs_DLPFC_Fix.mat'), 'TFRs')


%% Alpha Analysis
eventBand = [8,12]; %Frequency range of spectral events
fVec = (1:30); %Vector of fequency values over which to calculate TFR
Fs = 150; %Sampling rate of time-series
findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
vis = false; %Generate standard visualization plots for event features across all subjects/sessions
%tVec = (1/Fs:1/Fs:1);
%         classLabels = 4+zeros(1,size(avgData,1))

%% group by region and then run spectral event toolbox 
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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_specEV_Frontal_Fix.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_TFRs_Frontal_Fix.mat'), 'TFRs')


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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_specEV_Occipital_Fix.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_TFRs_Occipital_Fix.mat'), 'TFRs')

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_specEV_Parietal_Fix.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_TFRs_Parietal_Fix.mat'), 'TFRs')

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


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_specEV_DLPFC_Fix.mat'), 'specEv_struct')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_TFRs_DLPFC_Fix.mat'), 'TFRs')

