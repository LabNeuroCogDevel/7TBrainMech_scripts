
%% Extract our data from the large struct

addpath(('/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/'))
addpath((genpath('Functions')));
addpath(hera('/Projects/7TBrainMech/scripts/fieldtrip-20191127'))
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


%% Alpha

specEv_struct = load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Alpha\Delay5_6\Alpha_specEV_DLPFC_Delay_5_6.mat');
specEv_struct = specEv_struct.specEv_struct;

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


% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Delay5_6/Alpha_AvgEventNumber_5_6.mat'), 'AvgEventNumber_PerSubject')
% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Delay5_6/Alpha_AvgEventDuration_5_6.mat'), 'AvgEventDuration_PerSubject')
% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Delay5_6/Alpha_AvgPower_5_6.mat'), 'AvgPower_PerSubject')
% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Delay5_6/Alpha_AvgEventMaxPower_5_6.mat'), 'AvgEventMaxPower_PerSubject')
% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Delay5_6/Alpha_AvgEventMaxFreq_5_6.mat'), 'AvgEventMaxFreq_PerSubject')


AlphaT = table('Size', [0, 5], 'VariableTypes', {'string', 'double', 'double','double','double'});
AlphaT.Properties.VariableNames = {'Subject', 'Trial' ,'Alpha_Trial_Power','Alpha_Event_Number','Alpha_Event_Duration'};

%Extract info trial by trial
for i = 1:length(specEv_struct) %Subjects
    clear Trial_power
    clear Trial_eventDuration
    clear Trial_eventNumber
    
    
    T = table('Size', [length(Power{1,i}), 5], 'VariableTypes', {'string', 'double', 'double','double','double'});
    T.Properties.VariableNames = {'Subject', 'Trial' ,'Alpha_Trial_Power','Alpha_Event_Number','Alpha_Event_Duration'};
    
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
    Subject_peakFrequency = EventMaxFreq{1,i};
    
    Subject_peakPower = EventMaxPower{1,i};
    
    
    
    if isempty(Power{1,i}) || isempty(EventNumber{1,i}) || isempty(EventDuration{1,i}) || isempty( EventMaxFreq(1,i)) || isempty(EventMaxPower(1,i))
        continue
    end
    
    T.Alpha_Trial_Power = Subject_power;
    T.Alpha_Event_Number = Subject_channel_eventNumber;
    T.Alpha_Event_Duration = Subject_channel_eventDuration;
    
    T.Trial = [1:length(T.Alpha_Trial_Power)]';
    T.Subject(1:length(T.Alpha_Trial_Power)) = idvalues(i,:);
    AlphaT = [AlphaT; T];
    
end

writetable(AlphaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Delay5_6/Alpha_DLPFC_data_trialLevel.csv'));
 %%

% peak frequency and power

AlphaT = table('Size', [0, 4], 'VariableTypes', {'string', 'double', 'double','double'});
AlphaT.Properties.VariableNames = {'Subject', 'Trial', 'Alpha_Peak_Frequency', 'Alpha_Peak_Power'};
% 
% load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Alpha\Fix\Alpha_AvgEventMaxFreqFix.mat')
% load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Alpha\Fix\Alpha_AvgEventMaxPowerFix.mat')

%Extract info trial by trial
for i = 1:length(specEv_struct) %Subjects
    
    
    T = table('Size', [length(EventMaxFreq{1,i}), 4], 'VariableTypes', {'string', 'double', 'double','double'});
    T.Properties.VariableNames = {'Subject', 'Trial', 'Alpha_Peak_Frequency', 'Alpha_Peak_Power'};
    
    if isempty(EventMaxFreq{1,i}) || isempty(EventMaxPower{1,i})
        continue
    end
    
    
    Subject_peakFrequency = EventMaxFreq{1,i};
    
    Subject_peakPower = EventMaxPower{1,i};
    
    
    
    if isempty( EventMaxFreq(1,i)) || isempty(EventMaxPower(1,i))
        continue
    end
    
    
    T.Alpha_Peak_Frequency = Subject_peakFrequency;
    T.Alpha_Peak_Power = Subject_peakPower;
    T.Trial = [1:length(T.Alpha_Peak_Frequency)]';
    T.Subject(1:length(T.Alpha_Peak_Frequency)) = idvalues(i);
    AlphaT = [AlphaT; T];
    
end

writetable(AlphaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Delay5_6/Alpha_Subs_PeakFreq_5_6.csv'));


%% Beta
specEv_struct = load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Beta\Delay5_6\Beta_specEV_DLPFC_Delay_5_6.mat');
specEv_struct = specEv_struct.specEv_struct;

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

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Delay5_6/Beta_EventNumber5_6.mat'), 'EventNumber')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Delay5_6/Beta_EventDuration5_6.mat'), 'EventDuration')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Delay5_6/Beta_Power5_6.mat'), 'Power')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Delay5_6/Beta_EventMaxPower5_6.mat'), 'EventMaxPower')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Delay5_6/Beta_EventMaxFreq5_6.mat'), 'EventMaxFreq')


for i = 1:length(specEv_struct)
    
    AvgPower_PerSubject(1,i) = mean(Power{1,i});
    AvgEventNumber_PerSubject(1,i) = mean(EventNumber{1,i});
    AvgEventDuration_PerSubject(1,i) = mean(EventDuration{1,i});
    AvgEventMaxPower_PerSubject(1,i) = mean(EventMaxPower{1,i});
    AvgEventMaxFreq_PerSubject(1,i) = mean(EventMaxFreq{1,i});
    SDPower_PerSubject(1,i) = std(Power{1,i});
    
end


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Delay5_6/Beta_AvgEventNumber5_6.mat'), 'AvgEventNumber_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Delay5_6/Beta_AvgEventDuration5_6.mat'), 'AvgEventDuration_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Delay5_6/Beta_AvgPower5_6.mat'), 'AvgPower_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Delay5_6/Beta_AvgEventMaxPower5_6.mat'), 'AvgEventMaxPower_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Delay5_6/Beta_AvgEventMaxFreq5_6.mat'), 'AvgEventMaxFreq_PerSubject')


BetaT = table('Size', [0, 5], 'VariableTypes', {'string', 'double', 'double','double','double'});
BetaT.Properties.VariableNames = {'Subject', 'Trial' ,'Beta_Trial_Power','Beta_Event_Number','Beta_Event_Duration'};

%Extract info trial by trial
for i = 1:length(specEv_struct) %Subjects
    clear Trial_power
    clear Trial_eventDuration
    clear Trial_eventNumber
    
    T = table('Size', [length(Power{1,i}), 5], 'VariableTypes', {'string', 'double', 'double','double','double'});
    T.Properties.VariableNames = {'Subject', 'Trial' ,'Beta_Trial_Power','Beta_Event_Number','Beta_Event_Duration'};
    
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
    
    T.Beta_Trial_Power = Subject_power;
    T.Beta_Event_Number = Subject_channel_eventNumber;
    T.Beta_Event_Duration = Subject_channel_eventDuration;
    T.Trial = [1:length(T.Beta_Trial_Power)]';
    T.Subject(1:length(T.Beta_Trial_Power)) = idvalues(i,:);
    BetaT = [BetaT; T];
    
end

writetable(BetaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Delay5_6/Beta_DLPFC_trialLevel.csv'));

%% peak frequency and power

BetaT = table('Size', [0, 4], 'VariableTypes', {'string', 'double', 'double','double'});
BetaT.Properties.VariableNames = {'Subject', 'Trial', 'Beta_Peak_Frequency', 'Beta_Peak_Power'};
% 
% load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Beta\Delay5_6\Beta_EventMaxFreq5_6.mat')
% load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Beta\Delay5_6\Beta_EventMaxPower5_6.mat')
% %Extract info trial by trial
for i = 1:length(specEv_struct) %Subjects
    
    
    T = table('Size', [length(EventMaxFreq{1,i}), 4], 'VariableTypes', {'string', 'double', 'double','double'});
    T.Properties.VariableNames = {'Subject', 'Trial', 'Beta_Peak_Frequency', 'Beta_Peak_Power'};
    
    if isempty(EventMaxFreq{1,i}) || isempty(EventMaxPower{1,i})
        continue
    end
    
    
    Subject_peakFrequency = EventMaxFreq{1,i};
    
    Subject_peakPower = EventMaxPower{1,i};
    
    
    
    if isempty( EventMaxFreq(1,i)) || isempty(EventMaxPower(1,i))
        continue
    end
    
    
    T.Beta_Peak_Frequency = Subject_peakFrequency;
    T.Beta_Peak_Power = Subject_peakPower;
    T.Trial = [1:length(T.Beta_Peak_Frequency)]';
    T.Subject(1:length(T.Beta_Peak_Frequency)) = Subjects(i);
    BetaT = [BetaT; T];
    
end

writetable(BetaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Delay5_6/Beta_Subs_PeakFreq_Power_5_6.csv'));




%% theta
specEv_struct = load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Theta\Delay5_6\Theta_specEV_DLPFC_Delay_5_6.mat');
specEv_struct = specEv_struct.specEv_struct;

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

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Delay5_6/Theta_EventNumber5_6.mat'), 'EventNumber')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Delay5_6/Theta_EventDuration5_6.mat'), 'EventDuration')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Delay5_6/Theta_Power5_6.mat'), 'Power')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Delay5_6/Theta_EventMaxPower5_6.mat'), 'EventMaxPower')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Delay5_6/Theta_EventMaxFreq5_6.mat'), 'EventMaxFreq')


for i = 1:length(specEv_struct)
    
    AvgPower_PerSubject(1,i) = mean(Power{1,i});
    AvgEventNumber_PerSubject(1,i) = mean(EventNumber{1,i});
    AvgEventDuration_PerSubject(1,i) = mean(EventDuration{1,i});
    AvgEventMaxPower_PerSubject(1,i) = mean(EventMaxPower{1,i});
    AvgEventMaxFreq_PerSubject(1,i) = mean(EventMaxFreq{1,i});
    SDPower_PerSubject(1,i) = std(Power{1,i});
    
end

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Delay5_6/Theta_AvgEventNumber5_6.mat'), 'AvgEventNumber_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Delay5_6/Theta_AvgEventDuration5_6.mat'), 'AvgEventDuration_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Delay5_6/Theta_AvgPower5_6.mat'), 'AvgPower_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Delay5_6/Theta_AvgEventMaxPower5_6.mat'), 'AvgEventMaxPower_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Delay5_6/Theta_AvgEventMaxFreq5_6.mat'), 'AvgEventMaxFreq_PerSubject')



ThetaT = table('Size', [0, 5], 'VariableTypes', {'string', 'double', 'double','double','double'});
ThetaT.Properties.VariableNames = {'Subject', 'Trial' ,'Theta_Trial_Power','Theta_Event_Number','Theta_Event_Duration'};

%Extract info trial by trial
for i = 1:length(specEv_struct) %Subjects
    clear Trial_power
    clear Trial_eventDuration
    clear Trial_eventNumber
    
    T = table('Size', [length(Power{1,i}), 5], 'VariableTypes', {'string', 'double', 'double','double','double'});
    T.Properties.VariableNames = {'Subject', 'Trial' ,'Theta_Trial_Power','Theta_Event_Number','Theta_Event_Duration'};
    
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

    T.Theta_Trial_Power = Subject_power;
    T.Theta_Event_Number = Subject_channel_eventNumber;
    T.Theta_Event_Duration = Subject_channel_eventDuration;
    T.Trial = [1:length(T.Theta_Trial_Power)]';
    T.Subject(1:length(T.Theta_Trial_Power)) = idvalues(i,:);
    ThetaT = [ThetaT; T];
    
    
end

writetable(ThetaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Delay5_6/Theta_DLPFC_trialLevel.csv'));



%% peak frequency and power

ThetaT = table('Size', [0, 4], 'VariableTypes', {'string', 'double', 'double','double'});
ThetaT.Properties.VariableNames = {'Subject', 'Trial', 'Theta_Peak_Frequency', 'Theta_Peak_Power'};
% 
% load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Theta\Delay5_6\Theta_EventMaxFreq5_6.mat')
% load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Theta\Delay5_6\Theta_EventMaxPower5_6.mat')
% %Extract info trial by trial
for i = 1:length(specEv_struct) %Subjects
    
    
    T = table('Size', [length(EventMaxFreq{1,i}), 4], 'VariableTypes', {'string', 'double', 'double','double'});
    T.Properties.VariableNames = {'Subject', 'Trial', 'Theta_Peak_Frequency', 'Theta_Peak_Power'};
    
    if isempty(EventMaxFreq{1,i}) || isempty(EventMaxPower{1,i})
        continue
    end
    
    
    Subject_peakFrequency = EventMaxFreq{1,i};
    
    Subject_peakPower = EventMaxPower{1,i};
    
    
    
    if isempty( EventMaxFreq(1,i)) || isempty(EventMaxPower(1,i))
        continue
    end
    
    
    T.Theta_Peak_Frequency = Subject_peakFrequency;
    T.Theta_Peak_Power = Subject_peakPower;
    T.Trial = [1:length(T.Theta_Peak_Frequency)]';
    T.Subject(1:length(T.Theta_Peak_Frequency)) = Subjects(i);
    ThetaT = [ThetaT; T];
    
end

writetable(ThetaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Delay5_6/Theta_Subs_PeakFreq_Power5_6.csv'));


%% Gamma
specEv_struct = load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Gamma\Delay5_6\Gamma_specEV_DLPFC_Delay_5_6.mat');
specEv_struct = specEv_struct.specEv_struct; 

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

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Delay5_6/Gamma_EventNumber5_6.mat'), 'EventNumber')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Delay5_6/Gamma_EventDuration5_6.mat'), 'EventDuration')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Delay5_6/Gamma_Power5_6.mat'), 'Power')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Delay5_6/Gamma_EventMaxPower5_6.mat'), 'EventMaxPower')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Delay5_6/Gamma_EventMaxFreq5_6.mat'), 'EventMaxFreq')


for i = 1:length(specEv_struct)
    
    AvgPower_PerSubject(1,i) = mean(Power{1,i});
    AvgEventNumber_PerSubject(1,i) = mean(EventNumber{1,i});
    AvgEventDuration_PerSubject(1,i) = mean(EventDuration{1,i});
    AvgEventMaxPower_PerSubject(1,i) = mean(EventMaxPower{1,i});
    AvgEventMaxFreq_PerSubject(1,i) = mean(EventMaxFreq{1,i});
    SDPower_PerSubject(1,i) = std(Power{1,i});
    
end

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Delay5_6/Gamma_AvgEventNumber5_6.mat'), 'AvgEventNumber_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Delay5_6/Gamma_AvgEventDuration5_6.mat'), 'AvgEventDuration_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Delay5_6/Gamma_AvgPower5_6.mat'), 'AvgPower_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Delay5_6/Gamma_AvgEventMaxPower5_6.mat'), 'AvgEventMaxPower_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Delay5_6/Gamma_AvgEventMaxFreq5_6.mat'), 'AvgEventMaxFreq_PerSubject')

GammaT = table('Size', [0, 5], 'VariableTypes', {'string', 'double', 'double','double','double'});
GammaT.Properties.VariableNames = {'Subject', 'Trial' ,'Gamma_Trial_Power','Gamma_Event_Number','Gamma_Event_Duration'};

%Extract info trial by trial
for i = 1:length(specEv_struct) %Subjects
    clear Trial_power
    clear Trial_eventDuration
    clear Trial_eventNumber
    
    T = table('Size', [length(Power{1,i}), 5], 'VariableTypes', {'string', 'double', 'double','double','double'});
    T.Properties.VariableNames = {'Subject', 'Trial' ,'Gamma_Trial_Power','Gamma_Event_Number','Gamma_Event_Duration'};
    
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
    GammaT = [GammaT; T];
    
    
end

writetable(GammaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Delay3_4/Gamma_subs_3_4.csv'));


%% peak frequency and power

GammaT = table('Size', [0, 4], 'VariableTypes', {'string', 'double', 'double','double'});
GammaT.Properties.VariableNames = {'Subject', 'Trial', 'Gamma_Peak_Frequency', 'Gamma_Peak_Power'};
% 
% load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Gamma\Delay5_6\Gamma_EventMaxFreq5_6.mat')
% load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Gamma\Delay5_6\Gamma_EventMaxPower5_6.mat')
% %Extract info trial by trial
for i = 1:length(specEv_struct) %Subjects
    
    
    T = table('Size', [length(EventMaxFreq{1,i}), 4], 'VariableTypes', {'string', 'double', 'double','double'});
    T.Properties.VariableNames = {'Subject', 'Trial', 'Gamma_Peak_Frequency', 'Gamma_Peak_Power'};
    
    if isempty(EventMaxFreq{1,i}) || isempty(EventMaxPower{1,i})
        continue
    end
    
    
    Subject_peakFrequency = EventMaxFreq{1,i};
    
    Subject_peakPower = EventMaxPower{1,i};
    
    
    
    if isempty( EventMaxFreq(1,i)) || isempty(EventMaxPower(1,i))
        continue
    end
    
    
    T.Gamma_Peak_Frequency = Subject_peakFrequency;
    T.Gamma_Peak_Power = Subject_peakPower;
    T.Trial = [1:length(T.Gamma_Peak_Frequency)]';
    T.Subject(1:length(T.Gamma_Peak_Frequency)) = Subjects(i);
    GammaT = [GammaT; T];
    
end

writetable(GammaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Delay5_6/Gamma_Subs_PeakFreq_Power5_6.csv'));




%%

GrandTable = innerjoin(GammaT, ThetaT);
GrandTable = innerjoin(GrandTable, BetaT);
GrandTable = innerjoin(GrandTable, AlphaT);

writetable(GrandTable, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/GrandTable.csv'));

addpath(('Z:/DB_SQL/'));

all_ages = db_query('select id ||''_''|| to_char(vtimestamp,''YYYYMMDD'') as IDvalues, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg''  order by id, age ');
all_ages.Subject = char(all_ages.Subject);
GrandTable.Subject = char(GrandTable.Subject);
GrandTable = innerjoin(GrandTable, all_ages);


writetable(GrandTable, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/GrandTable_withAges.csv'));

stats = fitlme(GrandTable ,' Gamma_Trial_Power_Mean ~ age + (1|Subject) + (age - 1| Subject)' );



