%%
% For Terminal: addpath(('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/'))


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

numSubj = length(setfiles0);
x = cell(1,numSubj);
classLabels = cell(1,numSubj);




%% Gamma Analysis

for i = 1 : (numSubj)
    inputfile = setfiles{i};
    sEEG_data = load(inputfile); 
    data = sEEG_data.data;
    avg_data = mean(data,2);
    x{i} = avg_data(60001:120000, :);
    classLabels{i} = 1+zeros(1,size(x{i},2));

end

newX = cell(1, numSubj); 

for j = 1: length(x)
    subject = x{j};
    newSubject(:,1)= subject(1:10000, 1); 
    newSubject(:,2)= subject(10001:20000, 1); 
    newSubject(:,3)= subject(20001:30000, 1); 
    newSubject(:,4)= subject(30001:40000, 1); 
    newSubject(:,5)= subject(40001:50000, 1); 
    newSubject(:,6)= subject(40001:50000, 1); 

    newX{j} = newSubject; 
end



        cfg = [];
        eventBand = [30,75]; %Frequency range of spectral events
        fVec = (1:75); %Vector of fequency values over which to calculate TFR
        Fs = 1000; %Sampling rate of time-series
        findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
        vis = true; %Generate standard visualization plots for event features across all subjects/sessions
        %tVec = (1/Fs:1/Fs:1);
 
        [specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  newX ,classLabels);

        save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Gamma/Gamma_SpecEvents_Trials.mat'), 'specEv_struct')
    

%% High Gamma

for i = 1 : (numSubj)
    inputfile = setfiles{i};
    sEEG_data = load(inputfile); 
    data = sEEG_data.data;
    avg_data = mean(data,2);
    x{i} = avg_data(60001:120000, :);
    classLabels{i} = 1+zeros(1,size(x{i},2));

    
end

newX = cell(1, numSubj); 

for j = 1: length(x)
    subject = x{j};
    newSubject(:,1)= subject(1:10000, 1); 
    newSubject(:,2)= subject(10001:20000, 1); 
    newSubject(:,3)= subject(20001:30000, 1); 
    newSubject(:,4)= subject(30001:40000, 1); 
    newSubject(:,5)= subject(40001:50000, 1); 
    newSubject(:,6)= subject(40001:50000, 1); 

    newX{j} = newSubject; 
end




        cfg = [];
        eventBand = [75,200]; %Frequency range of spectral events
        fVec = (1:200); %Vector of fequency values over which to calculate TFR
        Fs = 1000; %Sampling rate of time-series
        findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
        vis = true; %Generate standard visualization plots for event features across all subjects/sessions
        %tVec = (1/Fs:1/Fs:1);
 
        [specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  newX ,classLabels);

        save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/HighGamma/HighGamma_SpecEvents_Trials.mat'), 'specEv_struct')
    

%% Beta
for i = 1 : (numSubj)
    inputfile = setfiles{i};
    sEEG_data = load(inputfile); 
    data = sEEG_data.data;
    avg_data = mean(data,2);
    x{i} = avg_data(60001:120000, :);
    classLabels{i} = 1+zeros(1,size(x{i},2));

    
end

newX = cell(1, numSubj); 

for j = 1: length(x)
    subject = x{j};
    newSubject(:,1)= subject(1:10000, 1); 
    newSubject(:,2)= subject(10001:20000, 1); 
    newSubject(:,3)= subject(20001:30000, 1); 
    newSubject(:,4)= subject(30001:40000, 1); 
    newSubject(:,5)= subject(40001:50000, 1); 
    newSubject(:,6)= subject(40001:50000, 1); 

    newX{j} = newSubject; 
end




        cfg = [];
        eventBand = [13,30]; %Frequency range of spectral events
        fVec = (1:35); %Vector of fequency values over which to calculate TFR
        Fs = 1000; %Sampling rate of time-series
        findMethod = 1; %Event-finding method (1 allows for maximal overlap while 2 limits overlap in each respective suprathreshold region)
        vis = true; %Generate standard visualization plots for event features across all subjects/sessions
        %tVec = (1/Fs:1/Fs:1);
 
        [specEv_struct, TFRs, X] = spectralevents(cfg, eventBand, fVec, Fs, findMethod, vis,  newX ,classLabels);

        save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/sEEG/Beta/Beta_SpecEvents_Trials.mat'), 'specEv_struct')
    


