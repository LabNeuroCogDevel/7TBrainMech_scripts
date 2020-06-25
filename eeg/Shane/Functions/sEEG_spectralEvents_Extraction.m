
addpath(('/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/'))
addpath(genpath('Functions'));
addpath(hera('/Projects/7TBrainMech/scripts/fieldtrip-20191127'))
ft_defaults

datapath = hera('/Projects/7TBrainMech/scripts/eeg/Shane/sEEG/raw_data');

%load in all the files
setfiles0 = dir([datapath,'/*.mat']);
setfiles = {};

for epo = 1:length(setfiles0)
    setfiles{epo,1} = fullfile(datapath, setfiles0(epo).name); % cell array with EEG file names
    % setfiles = arrayfun(@(x) fullfile(folder, x.name), setfiles(~[setfiles.isdir]),folder, 'Uni',0); % cell array with EEG file names
end

for j = 1 : length(setfiles0)
    idvalues(j,:) = (setfiles0(j).name(1:7));
end

%% Gamma

gammaStruct = load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\sEEG\Gamma\Gamma_SpecEvents_Trials.mat');
gammaStruct = gammaStruct.specEv_struct;

EventNumber = cell(1, length(gammaStruct));
EventDuration = cell(1, length(gammaStruct));
Power = cell(1, length(gammaStruct));
EventMaxPower = cell(1, length(gammaStruct));
EventMaxFreq = cell(1, length(gammaStruct));


for i = 1:length(gammaStruct)
    
    subject = gammaStruct(i);
    if isempty(subject.TrialSummary)
        continue
    end
    
    EventNumber{1,i} = subject.TrialSummary.TrialSummary.eventnumber;
    EventDuration{1,i} = subject.TrialSummary.TrialSummary.meaneventduration;
    Power{1,i} = subject.TrialSummary.TrialSummary.meaneventpower;
    EventMaxPower{1,i} = subject.Events.Events.maximapower;
    EventMaxFreq{1,i} = subject.Events.Events.maximafreq;
    
    
end

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Gamma/Gamma_EventNumber.mat'), 'EventNumber')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Gamma/Gamma_EventDuration.mat'), 'EventDuration')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Gamma/Gamma_Power.mat'), 'Power')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Gamma/Gamma_EventMaxPower.mat'), 'EventMaxPower')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Gamma/Gamma_EventMaxFreq.mat'), 'EventMaxFreq')

for i = 1:length(gammaStruct)
    
    AvgPower_PerSubject(1,i) = mean(Power{1,i});
    AvgEventNumber_PerSubject(1,i) = mean(EventNumber{1,i});
    AvgEventDuration_PerSubject(1,i) = mean(EventDuration{1,i});
    AvgEventMaxPower_PerSubject(1,i) = mean(EventMaxPower{1,i});
    AvgEventMaxFreq_PerSubject(1,i) = mean(EventMaxFreq{1,i});
    SDPower_PerSubject(1,i) = std(Power{1,i});
    
end


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Gamma/Gamma_AvgEventNumber.mat'), 'AvgEventNumber_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Gamma/Gamma_AvgEventDuration.mat'), 'AvgEventDuration_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Gamma/Gamma_AvgPower.mat'), 'AvgPower_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Gamma/Gamma_AvgEventMaxPower.mat'), 'AvgEventMaxPower_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Gamma/Gamma_AvgEventMaxFreq.mat'), 'AvgEventMaxFreq_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Gamma/Gamma_SDpower.mat'), 'SDPower_PerSubject')



AvgEventDuration_PerSubject = AvgEventDuration_PerSubject'; 
AvgEventMaxFreq_PerSubject = AvgEventMaxFreq_PerSubject'; 
AvgEventMaxPower_PerSubject = AvgEventMaxPower_PerSubject'; 
AvgEventNumber_PerSubject = AvgEventNumber_PerSubject'; 
AvgPower_PerSubject = AvgPower_PerSubject';

sEEG_GammaT = table('Size', [size(idvalues,1), 6], 'VariableTypes', {'string', 'double','double','double','double','double'});
sEEG_GammaT.Properties.VariableNames = {'Subject','Gamma_Trial_Power','Gamma_Event_Number','Gamma_Event_Duration', 'Gamma_Peak_Frequency', 'Gamma_Peak_Power'};
sEEG_GammaT.Subject = idvalues;
sEEG_GammaT.Gamma_Trial_Power = AvgPower_PerSubject; 
sEEG_GammaT.Gamma_Event_Number = AvgEventNumber_PerSubject; 
sEEG_GammaT.Gamma_Event_Duration = AvgEventDuration_PerSubject; 
sEEG_GammaT.Gamma_Peak_Frequency = AvgEventMaxFreq_PerSubject; 
sEEG_GammaT.Gamma_Peak_Power = AvgEventMaxPower_PerSubject;

writetable(sEEG_GammaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Gamma/sEEG_Gamma.csv'));

%Extract info trial by trial

GammaT = table('Size', [0, 5], 'VariableTypes', {'string', 'double', 'double','double','double'});
GammaT.Properties.VariableNames = {'Subject', 'Trial' ,'Gamma_Trial_Power','Gamma_Event_Number','Gamma_Event_Duration'};
 

for i = 1:length(gammaStruct) %Subjects
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

writetable(GammaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Gamma/Gamma_alldata_trials.csv'));

% peak frequency and power 

GammaT = table('Size', [0, 4], 'VariableTypes', {'string', 'double', 'double','double'});
GammaT.Properties.VariableNames = {'Subject', 'Trial', 'Gamma_Peak_Frequency', 'Gamma_Peak_Power'};
 
%Extract info trial by trial
for i = 1:length(gammaStruct) %Subjects
 
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
T.Subject(1:length(T.Gamma_Peak_Frequency)) = idvalues(i,:);
T.Trial = j + zeros(1,length(T.Gamma_Peak_Frequency))';
GammaT = [GammaT; T];

end

writetable(GammaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Gamma/Gamma_all_PeakFreq_PowerFix.csv'));


%% High Gamma
highGammaStruct = load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\sEEG\HighGamma\HighGamma_SpecEvents_Trials.mat');
highGammaStruct = highGammaStruct.specEv_struct;

EventNumber = cell(1, length(highGammaStruct));
EventDuration = cell(1, length(highGammaStruct));
Power = cell(1, length(highGammaStruct));
EventMaxPower = cell(1, length(highGammaStruct));
EventMaxFreq = cell(1, length(highGammaStruct));


for i = 1:length(highGammaStruct)
    
    subject = highGammaStruct(i);
    if isempty(subject.TrialSummary)
        continue
    end
    
    EventNumber{1,i} = subject.TrialSummary.TrialSummary.eventnumber;
    EventDuration{1,i} = subject.TrialSummary.TrialSummary.meaneventduration;
    Power{1,i} = subject.TrialSummary.TrialSummary.meaneventpower;
    EventMaxPower{1,i} = subject.Events.Events.maximapower;
    EventMaxFreq{1,i} = subject.Events.Events.maximafreq;
    
    
end

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/HighGamma/HighGamma_EventNumber.mat'), 'EventNumber')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/HighGamma/HighGamma_EventDuration.mat'), 'EventDuration')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/HighGamma/HighGamma_Power.mat'), 'Power')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/HighGamma/HighGamma_EventMaxPower.mat'), 'EventMaxPower')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/HighGamma/HighGamma_EventMaxFreq.mat'), 'EventMaxFreq')

for i = 1:length(highGammaStruct)
    
    AvgPower_PerSubject(1,i) = mean(Power{1,i});
    AvgEventNumber_PerSubject(1,i) = mean(EventNumber{1,i});
    AvgEventDuration_PerSubject(1,i) = mean(EventDuration{1,i});
    AvgEventMaxPower_PerSubject(1,i) = mean(EventMaxPower{1,i});
    AvgEventMaxFreq_PerSubject(1,i) = mean(EventMaxFreq{1,i});
    SDPower_PerSubject(1,i) = std(Power{1,i});
    
end


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/HighGamma/HighGamma_AvgEventNumber.mat'), 'AvgEventNumber_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/HighGamma/HighGamma_AvgEventDuration.mat'), 'AvgEventDuration_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/HighGamma/HighGamma_AvgPower.mat'), 'AvgPower_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/HighGamma/HighGamma_AvgEventMaxPower.mat'), 'AvgEventMaxPower_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/HighGamma/HighGamma_AvgEventMaxFreq.mat'), 'AvgEventMaxFreq_PerSubject')


AvgEventDuration_PerSubject = AvgEventDuration_PerSubject'; 
AvgEventMaxFreq_PerSubject = AvgEventMaxFreq_PerSubject'; 
AvgEventMaxPower_PerSubject = AvgEventMaxPower_PerSubject'; 
AvgEventNumber_PerSubject = AvgEventNumber_PerSubject'; 
AvgPower_PerSubject = AvgPower_PerSubject';

sEEG_HighGammaT = table('Size', [size(idvalues,1), 6], 'VariableTypes', {'string', 'double','double','double','double','double'});
sEEG_HighGammaT.Properties.VariableNames = {'Subject','HighGamma_Trial_Power','HighGamma_Event_Number','HighGamma_Event_Duration', 'HighGamma_Peak_Frequency', 'HighGamma_Peak_Power'};
sEEG_HighGammaT.Subject = idvalues;
sEEG_HighGammaT.HighGamma_Trial_Power = AvgPower_PerSubject; 
sEEG_HighGammaT.HighGamma_Event_Number = AvgEventNumber_PerSubject; 
sEEG_HighGammaT.HighGamma_Event_Duration = AvgEventDuration_PerSubject; 
sEEG_HighGammaT.HighGamma_Peak_Frequency = AvgEventMaxFreq_PerSubject; 
sEEG_HighGammaT.HighGamma_Peak_Power = AvgEventMaxPower_PerSubject;

writetable(sEEG_HighGammaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/HighGamma/sEEG_HighGamma.csv'));


%Extract info trial by trial

GammaT = table('Size', [0, 5], 'VariableTypes', {'string', 'double', 'double','double','double'});
GammaT.Properties.VariableNames = {'Subject', 'Trial' ,'HighGamma_Trial_Power','HighGamma_Event_Number','HighGamma_Event_Duration'};
 

for i = 1:length(highGammaStruct) %Subjects
    clear Trial_power
    clear Trial_eventDuration
    clear Trial_eventNumber
    
       T = table('Size', [length(Power{1,i}), 5], 'VariableTypes', {'string', 'double', 'double','double','double'});
       T.Properties.VariableNames = {'Subject', 'Trial' ,'HighGamma_Trial_Power','HighGamma_Event_Number','HighGamma_Event_Duration'};

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
    
  

    T.HighGamma_Trial_Power = Subject_power;
    T.HighGamma_Event_Number = Subject_channel_eventNumber;
    T.HighGamma_Event_Duration = Subject_channel_eventDuration;
    T.Trial = [1:length(T.HighGamma_Trial_Power)]';
    T.Subject(1:length(T.HighGamma_Trial_Power)) = idvalues(i,:);
   
    GammaT = [GammaT; T];
    
    
end

writetable(GammaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/HighGamma/HighGamma_alldata_trials.csv'));

% peak frequency and power 

GammaT = table('Size', [0, 4], 'VariableTypes', {'string', 'double', 'double','double'});
GammaT.Properties.VariableNames = {'Subject', 'Trial', 'HighGamma_Peak_Frequency', 'HighGamma_Peak_Power'};
 
%Extract info trial by trial
for i = 1:length(highGammaStruct) %Subjects
 
       T = table('Size', [length(EventMaxFreq{1,i}), 4], 'VariableTypes', {'string', 'double', 'double','double'});
       T.Properties.VariableNames = {'Subject', 'Trial', 'HighGamma_Peak_Frequency', 'HighGamma_Peak_Power'};

        if isempty(EventMaxFreq{1,i}) || isempty(EventMaxPower{1,i}) 
            continue
        end
        

        Subject_peakFrequency = EventMaxFreq{1,i}; 
        
        Subject_peakPower = EventMaxPower{1,i}; 
        

    
if isempty( EventMaxFreq(1,i)) || isempty(EventMaxPower(1,i))
    continue
end


T.HighGamma_Peak_Frequency = Subject_peakFrequency; 
T.HighGamma_Peak_Power = Subject_peakPower; 
T.Trial = i + zeros(1,length(T.HighGamma_Peak_Frequency))';
T.Subject(1:length(T.HighGamma_Peak_Frequency)) = idvalues(i,:);
GammaT = [GammaT; T];

end

writetable(GammaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/HighGamma/HighGamma_all_PeakFreq_PowerFix.csv'));


%% Beta

betaStruct = load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\sEEG\Beta\Beta_SpecEvents_Trials.mat');
betaStruct = betaStruct.specEv_struct;

EventNumber = cell(1, length(betaStruct));
EventDuration = cell(1, length(betaStruct));
Power = cell(1, length(betaStruct));
EventMaxPower = cell(1, length(betaStruct));
EventMaxFreq = cell(1, length(betaStruct));


for i = 1:length(betaStruct)
    
    subject = betaStruct(i);
    if isempty(subject.TrialSummary)
        continue
    end
    
    EventNumber{1,i} = subject.TrialSummary.TrialSummary.eventnumber;
    EventDuration{1,i} = subject.TrialSummary.TrialSummary.meaneventduration;
    Power{1,i} = subject.TrialSummary.TrialSummary.meaneventpower;
    EventMaxPower{1,i} = subject.Events.Events.maximapower;
    EventMaxFreq{1,i} = subject.Events.Events.maximafreq;
    
    
end

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Beta/Beta_EventNumber.mat'), 'EventNumber')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Beta/Beta_EventDuration.mat'), 'EventDuration')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Beta/Beta_Power.mat'), 'Power')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Beta/Beta_EventMaxPower.mat'), 'EventMaxPower')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Beta/Beta_EventMaxFreq.mat'), 'EventMaxFreq')

for i = 1:length(betaStruct)
    
    AvgPower_PerSubject(1,i) = mean(Power{1,i});
    AvgEventNumber_PerSubject(1,i) = mean(EventNumber{1,i});
    AvgEventDuration_PerSubject(1,i) = mean(EventDuration{1,i});
    AvgEventMaxPower_PerSubject(1,i) = mean(EventMaxPower{1,i});
    AvgEventMaxFreq_PerSubject(1,i) = mean(EventMaxFreq{1,i});
    SDPower_PerSubject(1,i) = std(Power{1,i});
    
end


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Beta/Beta_AvgEventNumber.mat'), 'AvgEventNumber_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Beta/Beta_AvgEventDuration.mat'), 'AvgEventDuration_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Beta/Beta_AvgPower.mat'), 'AvgPower_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Beta/Beta_AvgEventMaxPower.mat'), 'AvgEventMaxPower_PerSubject')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Beta/Beta_AvgEventMaxFreq.mat'), 'AvgEventMaxFreq_PerSubject')

AvgEventDuration_PerSubject = AvgEventDuration_PerSubject'; 
AvgEventMaxFreq_PerSubject = AvgEventMaxFreq_PerSubject'; 
AvgEventMaxPower_PerSubject = AvgEventMaxPower_PerSubject'; 
AvgEventNumber_PerSubject = AvgEventNumber_PerSubject'; 
AvgPower_PerSubject = AvgPower_PerSubject';

sEEG_BetaT = table('Size', [size(idvalues,1), 6], 'VariableTypes', {'string', 'double','double','double','double','double'});
sEEG_BetaT.Properties.VariableNames = {'Subject','Beta_Trial_Power','Beta_Event_Number','Beta_Event_Duration', 'Beta_Peak_Frequency', 'Beta_Peak_Power'};
sEEG_BetaT.Subject = idvalues;
sEEG_BetaT.Beta_Trial_Power = AvgPower_PerSubject; 
sEEG_BetaT.Beta_Event_Number = AvgEventNumber_PerSubject; 
sEEG_BetaT.Beta_Event_Duration = AvgEventDuration_PerSubject; 
sEEG_BetaT.Beta_Peak_Frequency = AvgEventMaxFreq_PerSubject; 
sEEG_BetaT.Beta_Peak_Power = AvgEventMaxPower_PerSubject;

writetable(sEEG_BetaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Beta/sEEG_Beta.csv'));



%Extract info trial by trial

BetaT = table('Size', [0, 5], 'VariableTypes', {'string', 'double', 'double','double','double'});
BetaT.Properties.VariableNames = {'Subject', 'Trial' ,'Beta_Trial_Power','Beta_Event_Number','Beta_Event_Duration'};
 

for i = 1:length(betaStruct) %Subjects
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

writetable(BetaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Beta/Beta_alldata_trials.csv'));

% peak frequency and power 

BetaT = table('Size', [0, 4], 'VariableTypes', {'string', 'double', 'double','double'});
BetaT.Properties.VariableNames = {'Subject', 'Trial', 'Beta_Peak_Frequency', 'Beta_Peak_Power'};
 
%Extract info trial by trial
for i = 1:length(betaStruct) %Subjects
 
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
T.Trial = i + zeros(1,length(T.Beta_Peak_Frequency))';
T.Subject(1:length(T.Beta_Peak_Frequency)) = idvalues(i,:);
BetaT = [BetaT; T];

end

writetable(BetaT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Beta/Beta_all_PeakFreq_PowerFix.csv'));















 