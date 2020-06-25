
% For Terminal: addpath(('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/'))


addpath(('/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/'))
addpath(genpath('Functions'));
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

numSubj = 148;
x = cell(1,numSubj);
classLabels = cell(1,numSubj);

%% Gamma Analysis
% clear AvgEventDuration
% clear AvgEventFSpan
% clear AvgEventNumber
% clear AvgPower
% clear peakPower


for i = 1 : (numSubj)
    inputfile = setfiles{i};

    clear events
    clear data
    clear hdr
    clear avgData
    clear classLabels

    hdr = ft_read_header(inputfile);
    data = ft_read_data(inputfile, 'header', hdr);
    events = ft_read_event(inputfile, 'header', hdr);

    cfg = [];
    cfg.dataset = inputfile;
    cfg.headerfile = inputfile;
    cfg.channel =   {'all', '-POz'};
    cfg.trialdef.eventtype = 'trigger';
    cfg.trialdef.eventvalue = '2';
    cfg.trialdef.prestim = 0;
    cfg.trialdef.poststim = 1;
    cfg.trialfun = 'ft_trialfun_general';
    cfg.trialdef.ntrials = 95;
    cfg.event = events;

    try

        [cfg]= ft_definetrial(cfg);

    catch
        continue;
    end


    [data] = ft_preprocessing(cfg);


    %redefine the trails to be between 1-2 seconds of the delay period
    cfg.trl = [];
    cfg = rmfield(cfg, 'trl');
    cfg.toilim = [0 1];
    data = ft_redefinetrial(cfg, data);

    for k = 1:size(data.label,1) %channels 
        for j = 1:length(data.trial) %trial 
            trialData = (data.trial{1,j});
            channel = trialData(k,:);
            avgData(j,:) = channel;
        end
%         if size(avgData,1) > 96
%             continue
%         end


%         eventBand = [30,75]; %Frequency range of spectral events
%         fVec = (1:75); %Vector of fequency values over which to calculate TFR
%         Fs = 150; %Sampling rate of time-series
%         findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
%         vis = true; %Generate standard visualization plots for event features across all subjects/sessions
%         %tVec = (1/Fs:1/Fs:1);
%         classLabels = );
% 
%         [specEv_struct, TFRs, X] = spectralevents(eventBand, fVec, Fs, findMethod, vis,  avgData' ,classLabels);
% 
% %         AvgEventNumber(k,i) = mean(specEv_struct.TrialSummary.TrialSummary.eventnumber);
% %         AvgEventDuration(k,i) = mean(specEv_struct.TrialSummary.TrialSummary.meaneventduration);
% %         AvgEventFSpan(k,i) = mean(specEv_struct.TrialSummary.TrialSummary.meaneventFspan);
% %         AvgPower(k,i) = mean(specEv_struct.TrialSummary.TrialSummary.meaneventpower);
% %         peakPower(k,i) = max(specEv_struct.TrialSummary.TrialSummary.meaneventpower);
% %         SDPower(i,1) = std(specEv_struct.TrialSummary.TrialSummary.meanpower);
% 
%            SE_Subs_Channel{i,k} = specEv_struct; 


    x{i} = avgData'; 
    classLabels{i} = 4+zeros(1,size(x{i},2));
    
    end
end

        eventBand = [30,75]; %Frequency range of spectral events
        fVec = (30:75); %Vector of fequency values over which to calculate TFR
        Fs = 150; %Sampling rate of time-series
        findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
        vis = true; %Generate standard visualization plots for event features across all subjects/sessions
        %tVec = (1/Fs:1/Fs:1);
 
        [specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  x ,classLabels);


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_SpecEvents_all_FIX.mat'), 'specEv_struct')


% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/GammaAvgEventNumber_allevents.mat'), 'AvgEventNumber')
% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/GammaAvgEventDuration_allevents.mat'), 'AvgEventDuration')
% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/GammaAvgPower_allevents.mat'), 'AvgPower')
% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/GammaPeakPower_allevents.mat'), 'peakPower')
% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/GammaSDPower_allevents.mat'), 'SDPower')


AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/ERPs/EdaDI.xlsx'));

addpath(('Z:/DB_SQL/'));

all_ages = db_query('select id ||''_''|| to_char(vtimestamp,''YYYYMMDD'') as IDvalues, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg''  order by id, age ');
all_ages.idvalues= char(all_ages.idvalues);

for j = 1 : length(setfiles0)

    idvalues(j,:) = (setfiles0(j).name(1:14));
end

MeanAvgEventNumber = mean(AvgEventNumber,1)';
MeanAvgEventDuration = mean(AvgEventDuration,1)';
MeanAvgPower = mean(AvgPower, 1)';
MeanpeakPower = mean(peakPower, 1)';


T = table(idvalues, MeanAvgEventNumber, MeanAvgEventDuration, MeanAvgPower, MeanpeakPower);
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_Spectral_Analysis_Table_allevents.mat'), 'T')

all_info = innerjoin(T, all_ages);



all_info = all_info(all_info.MeanAvgPower ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_Spectral_Analysis_Table_all_allevents.csv'));



DLPFC_AvgEventNumber = AvgEventNumber(6,:)'; 
DLPFC_AvgEventDuration = AvgEventDuration(6,:)'; 
DLPFC_AvgPower = AvgPower(6,:)'; 
DLPFC_peakPower = peakPower(6,:)'; 

DLPFC_T = table(idvalues, DLPFC_AvgEventNumber, DLPFC_AvgEventDuration, DLPFC_AvgPower, DLPFC_peakPower); 
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/DLPFC/DLPFC_Gamma_Spectral_Analysis_Table_allevents.mat'), 'T')


all_info = innerjoin(DLPFC_T, all_ages);


all_info = all_info(all_info.DLPFC_AvgEventNumber ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/DLPFC/DLPFC_Gamma_Spectral_Analysis_Table_all_allevents.csv'));


%% Theta Analysis
numSubj = 148;
x = cell(1,numSubj);
classLabels = cell(1,numSubj);
% SE_Subs_Channel = cell(length(setfiles), 63); 

% clear AvgEventDuration
% clear AvgEventFSpan
% clear AvgEventNumber
% clear AvgPower
% clear peakPower

for i = 1 : numSubj
    
    inputfile = setfiles{i};
    
    clear events
    clear data
    clear hdr
    clear avgData
    clear classLabels
    
    hdr = ft_read_header(inputfile);
    data = ft_read_data(inputfile, 'header', hdr);
    events = ft_read_event(inputfile, 'header', hdr);
    
    cfg = [];
    cfg.dataset = inputfile;
    cfg.headerfile = inputfile;
    cfg.channel = {'all', '-POz'};
    cfg.trialdef.eventtype = 'trigger';
    cfg.trialdef.eventvalue = '2';
    cfg.trialdef.prestim = 0;
    cfg.trialdef.poststim = 1;
    cfg.trialfun = 'ft_trialfun_general';
    cfg.trialdef.ntrials = 95;
    cfg.event = events;
    
    try
        
        [cfg]= ft_definetrial(cfg);
        
    catch
        continue;
    end
    
    
    [data] = ft_preprocessing(cfg);
    
    
    %redefine the trails to be between 1-2 seconds of the delay period
    cfg.trl = [];
    cfg = rmfield(cfg, 'trl');
    cfg.toilim = [0 1];
    data = ft_redefinetrial(cfg, data);
    
    for k = 1:size(data.label,1)
        for j = 1:length(data.trial)
            trialData = (data.trial{1,j});
            channel = trialData(k,:);
            avgData(j,:) = channel;
        end
        
        
          
%             AvgEventNumber(k,i) = mean(specEv_struct.TrialSummary.TrialSummary.eventnumber);
%             AvgEventDuration(k,i) = mean(specEv_struct.TrialSummary.TrialSummary.meaneventduration);
%             AvgEventFSpan(k,i) = mean(specEv_struct.TrialSummary.TrialSummary.meaneventFspan);
%             AvgPower(k,i) = mean(specEv_struct.TrialSummary.TrialSummary.meaneventpower);
%             peakPower(k,i) = max(specEv_struct.TrialSummary.TrialSummary.meaneventpower);
%     SDPower(i,1) = std(specEv_struct.TrialSummary.TrialSummary.meanpower);
       
%                    SE_Subs_Channel{i,k} = specEv_struct; 
    x{i} = avgData'; 
    classLabels{i} = 4+zeros(1,size(x{i},2));
    end
%        

end
eventBand = [4,7]; %Frequency range of spectral events
            fVec = (1:30); %Vector of fequency values over which to calculate TFR
            Fs = 150; %Sampling rate of time-series
            findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
            vis = true; %Generate standard visualization plots for event features across all subjects/sessions
            %tVec = (1/Fs:1/Fs:1);
%             classLabels = 4+zeros(1,size(avgData,1));
            
            [specEv_struct, TFRs, X] = spectralevents(eventBand, fVec, Fs, findMethod, vis,  x ,classLabels);
%             
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_SpecEvents_all_FIX.mat'), 'specEv_struct')

% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/ThetaAvgEventNumber_allevents.mat'), 'AvgEventNumber')
% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/ThetaAvgEventDuration_allevents.mat'), 'AvgEventDuration')
% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/ThetaAvgPower_allevents.mat'), 'AvgPower')
% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/ThetaPeakPower_allevents.mat'), 'peakPower')
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/ThetaSDPower_allevents.mat'), 'SDPower')

%
AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/ERPs/EdaDI.xlsx'));

addpath(('Z:/DB_SQL/'));

all_ages = db_query('select id ||''_''|| to_char(vtimestamp,''YYYYMMDD'') as IDvalues, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg''  order by id, age ');
all_ages.idvalues= char(all_ages.idvalues);

for j = 1 : length(setfiles0)

    idvalues(j,:) = (setfiles0(j).name(1:14));
end
%
MeanAvgEventNumber = mean(AvgEventNumber,1)';
MeanAvgEventDuration = mean(AvgEventDuration,1)';
MeanAvgPower = mean(AvgPower, 1)';
MeanpeakPower = mean(peakPower, 1)';

T = table(idvalues, MeanAvgEventNumber, MeanAvgEventDuration, MeanAvgPower, MeanpeakPower);
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_Spectral_Analysis_Table_allevents.mat'), 'T')

all_info = innerjoin(T, all_ages);



all_info = all_info(all_info.MeanAvgEventNumber ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_Spectral_Analysis_Table_all_allevents.csv'));



%theta DLPFC 
%pull out DLPFC
DLPFC_AvgEventNumber = AvgEventNumber(6,:)'; 
DLPFC_AvgEventDuration = AvgEventDuration(6,:)'; 
DLPFC_AvgPower = AvgPower(6,:)'; 
DLPFC_peakPower = peakPower(6,:)'; 

DLPFC_T = table(idvalues, DLPFC_AvgEventNumber, DLPFC_AvgEventDuration, DLPFC_AvgPower, DLPFC_peakPower); 
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/DLPFC/DLPFC_Theta_Spectral_Analysis_Table_allevents.mat'), 'T')


all_info = innerjoin(DLPFC_T, all_ages);


all_info = all_info(all_info.DLPFC_AvgEventNumber ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/DLPFC/DLPFC_Theta_Spectral_Analysis_Table_all_allevents.csv'));


%
%
%% Beta Analysis
numSubj = 148;
x = cell(1,numSubj);
classLabels = cell(1,numSubj);

% SE_Subs_Channel = cell(length(setfiles), 63); 

% clear AvgEventDuration
% clear AvgEventFSpan
% clear AvgEventNumber
% clear AvgPower
% clear peakPower

for i = 1 : numSubj
    
    inputfile = setfiles{i};
    
    clear events
    clear data
    clear hdr
    clear avgData
    clear classLabels
    
    hdr = ft_read_header(inputfile);
    data = ft_read_data(inputfile, 'header', hdr);
    events = ft_read_event(inputfile, 'header', hdr);
    
    cfg = [];
    cfg.dataset = inputfile;
    cfg.headerfile = inputfile;
    cfg.channel = {'all', '-POz'};
    cfg.trialdef.eventtype = 'trigger';
    cfg.trialdef.eventvalue = '2';
    cfg.trialdef.prestim = 0;
    cfg.trialdef.poststim = 1;
    cfg.trialfun = 'ft_trialfun_general';
    cfg.trialdef.ntrials = 95;
    cfg.event = events;
    
    try
        
        [cfg]= ft_definetrial(cfg);
        
    catch
        continue;
    end
    
    
    [data] = ft_preprocessing(cfg);
    
    
    %redefine the trails to be between 1-2 seconds of the delay period
    cfg.trl = [];
    cfg = rmfield(cfg, 'trl');
    cfg.toilim = [0 1];
    data = ft_redefinetrial(cfg, data);
    
    for k = 1:size(data.label,1)
        for j = 1:length(data.trial)
            trialData = (data.trial{1,j});
            channel = trialData(k,:);
            avgData(j,:) = channel;
        end
        
          
%             AvgEventNumber(k,i) = mean(specEv_struct.TrialSummary.TrialSummary.eventnumber);
%             AvgEventDuration(k,i) = mean(specEv_struct.TrialSummary.TrialSummary.meaneventduration);
%             AvgEventFSpan(k,i) = mean(specEv_struct.TrialSummary.TrialSummary.meaneventFspan);
%             AvgPower(k,i) = mean(specEv_struct.TrialSummary.TrialSummary.meaneventpower);
%             peakPower(k,i) = max(specEv_struct.TrialSummary.TrialSummary.meaneventpower);
%             SDPower(i,1) = std(specEv_struct.TrialSummary.TrialSummary.meanpower);
            
%                    SE_Subs_Channel{i,k} = specEv_struct; 

x{i} = avgData'; 
    classLabels{i} = 4+zeros(1,size(x{i},2));
    end
    

end
eventBand = [13,30]; %Frequency range of spectral events
            fVec = (1:30); %Vector of fequency values over which to calculate TFR
            Fs = 150; %Sampling rate of time-series
            findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
            vis = true; %Generate standard visualization plots for event features across all subjects/sessions
            %tVec = (1/Fs:1/Fs:1);
%             classLabels = 4+zeros(1,size(avgData,1));
            
            [specEv_struct, TFRs, X] = spectralevents(eventBand, fVec, Fs, findMethod, vis,  x ,classLabels);
            
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_SpecEvents_all_FIX.mat'), 'specEv_struct')

%
% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/BetaAvgEventNumber_allevents.mat'), 'AvgEventNumber')
% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/BetaAvgEventDuration_allevents.mat'), 'AvgEventDuration')
% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/BetaAvgPower_allevents.mat'), 'AvgPower')
% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/BetaPeakPower_allevents.mat'), 'peakPower')
% save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/BetaSDPower_allevents.mat'), 'SDPower')


AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/ERPs/EdaDI.xlsx'));

addpath(('Z:/DB_SQL/'));

all_ages = db_query('select id ||''_''|| to_char(vtimestamp,''YYYYMMDD'') as IDvalues, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg''  order by id, age ');
all_ages.idvalues= char(all_ages.idvalues);

for j = 1 : length(setfiles0)

    idvalues(j,:) = (setfiles0(j).name(1:14));
end


MeanAvgEventNumber = mean(AvgEventNumber,1)';
MeanAvgEventDuration = mean(AvgEventDuration,1)';
MeanAvgPower = mean(AvgPower, 1)';
MeanpeakPower = mean(peakPower, 1)';

T = table(idvalues, MeanAvgEventNumber, MeanAvgEventDuration, MeanAvgPower, MeanpeakPower);
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_Spectral_Analysis_Table_allevents.mat'), 'T')

all_info = innerjoin(T, all_ages);



all_info = all_info(all_info.MeanAvgEventNumber ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_Spectral_Analysis_Table_all_allevents.csv'));
%


%Beta DLPFC 
%pull out DLPFC
DLPFC_AvgEventNumber = AvgEventNumber(6,:)'; 
DLPFC_AvgEventDuration = AvgEventDuration(6,:)'; 
DLPFC_AvgPower = AvgPower(6,:)'; 
DLPFC_peakPower = peakPower(6,:)'; 

DLPFC_T = table(idvalues, DLPFC_AvgEventNumber, DLPFC_AvgEventDuration, DLPFC_AvgPower, DLPFC_peakPower); 
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/DLPFC/DLPFC_Beta_Spectral_Analysis_Table_allevents.mat'), 'T')


all_info = innerjoin(DLPFC_T, all_ages);


all_info = all_info(all_info.DLPFC_AvgEventNumber ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/DLPFC/DLPFC_Beta_Spectral_Analysis_Table_all_allevents.csv'));




SE_Subs_Channel = cell(length(setfiles), 63); 

%% Alpha Analysis
% clear AvgEventDuration
% clear AvgEventFSpan
% clear AvgEventNumber
% clear AvgPower
% clear peakPower
numSubj = 148;
x = cell(1,numSubj);
classLabels = cell(1,numSubj);


for i = 1 : numSubj
    inputfile = setfiles{i};

    clear events
    clear data
    clear hdr
    clear avgData
    clear classLabels

    hdr = ft_read_header(inputfile);
    data = ft_read_data(inputfile, 'header', hdr);
    events = ft_read_event(inputfile, 'header', hdr);

    cfg = [];
    cfg.dataset = inputfile;
    cfg.headerfile = inputfile;
    cfg.channel =   {'all', '-POz'};
    cfg.trialdef.eventtype = 'trigger';
    cfg.trialdef.eventvalue = '2';
    cfg.trialdef.prestim = 0;
    cfg.trialdef.poststim = 1;
    cfg.trialfun = 'ft_trialfun_general';
    cfg.trialdef.ntrials = 95;
    cfg.event = events;

    try

        [cfg]= ft_definetrial(cfg);

    catch
        continue;
    end


    [data] = ft_preprocessing(cfg);


    %redefine the trails to be between 1-2 seconds of the delay period
    cfg.trl = [];
    cfg = rmfield(cfg, 'trl');
    cfg.toilim = [0 1];
    data = ft_redefinetrial(cfg, data);

    for k = 1:size(data.label,1)
        for j = 1:length(data.trial)
            trialData = (data.trial{1,j});
            channel = trialData(k,:);
            avgData(j,:) = channel;
        end
%         if size(avgData,1) > 96
%             continue
%         end


      
%         AvgEventNumber(k,i) = mean(specEv_struct.TrialSummary.TrialSummary.eventnumber);
%         AvgEventDuration(k,i) = mean(specEv_struct.TrialSummary.TrialSummary.meaneventduration);
%         AvgEventFSpan(k,i) = mean(specEv_struct.TrialSummary.TrialSummary.meaneventFspan);
%         AvgPower(k,i) = mean(specEv_struct.TrialSummary.TrialSummary.meaneventpower);
%         peakPower(k,i) = max(specEv_struct.TrialSummary.TrialSummary.meaneventpower);
%         SDPower(i,1) = std(specEv_struct.TrialSummary.TrialSummary.meanpower);

%            SE_Subs_Channel{i,k} = specEv_struct; 
x{i} = avgData'; 
    classLabels{i} = 4+zeros(1,size(x{i},2));

    end
    


end

eventBand = [8,12]; %Frequency range of spectral events
fVec = (1:30); %Vector of fequency values over which to calculate TFR
Fs = 150; %Sampling rate of time-series
findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
vis = true; %Generate standard visualization plots for event features across all subjects/sessions
%tVec = (1/Fs:1/Fs:1);
%         classLabels = 4+zeros(1,size(avgData,1));

[specEv_struct, TFRs, X] = spectralevents(eventBand, fVec, Fs, findMethod, vis,  x ,classLabels);


save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Alpha/Alpha_SpecEvents_all_FIX.mat'), 'specEv_struct')




