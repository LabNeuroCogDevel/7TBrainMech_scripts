%% DELAY

% load in data
addpath(genpath('Functions'));
addpath(genpath(hera('Projects/7TBrainMech/scripts/eeg/Shane/Functions/resources/eeglab2022.1')))

eeglab

addpath(('/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/'))
addpath(genpath('Functions'));
addpath(hera('/Projects/7TBrainMech/scripts/fieldtrip-20220104'))
ft_defaults

% load in the x matrix,
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\traditionalEEGanalysis\Gamma_Xmatrix_3_4.mat')

% load in subject ID
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Gamma\Delay3_4\Gamma_Subs_3_4.mat')


datapath = hera('/Projects/7TBrainMech/scripts/eeg/Shane/Prep/AfterWhole/ICAwholeClean_homogenize');

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

Fs = 150;
L = 151;
for i = 1:numSubj

    sub = x{:,i};
    
    for j = 1:size(sub,2)
        trial = sub(:,j);
        fftTrial(:,j) = fft(trial); 
    end
    
    avgFFT = mean(fftTrial,2);
    newAvgFFT(:,i) = abs(avgFFT); 
    
end
f = Fs*(0:(L/2))/L;

% the the indices that correspond to the 30-75 hz range

idx = find(f > 30 & f <75); 
gammaBand = newAvgFFT(idx, :); 

avgGammaPower = abs((mean(gammaBand)));




%% Extract info and put into a table

PowerT = table('Size', [0, 2], 'VariableTypes', {'string', 'double'});
PowerT.Properties.VariableNames = {'Subject', 'Power'};


for isub = 1:numSubj
    
    if isempty(x{isub})
        continue
    else
    
   T = table('Size', [1, 2], 'VariableTypes', {'string', 'double'});
   T.Properties.VariableNames = {'Subject', 'Power'};


    subjectsPower = avgGammaPower(isub);
    subject = Subjects(isub); 
    
    T.Subject(1) = subject{1};
    T.Power = subjectsPower; 
 
    PowerT = [PowerT;T];
    end
    
end

writetable(PowerT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/traditionalEEGanalysis/gammaPower_traditionalMethod_Delay.csv'));



%% Find Power for Individual Channels

% load in the x matrix,
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\IndividualChannelsXmatrix_Delay_3_4.mat')

% load in subject ID
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Gamma\Delay3_4\Gamma_Subs_3_4.mat')

Fs = 150;
L = 151;

f = Fs*(0:(L/2))/L;

% the the indices that correspond to the 35-65 hz range
idx = find(f > 35 & f < 65); 

for i = 1:length(x)

    sub = x{:,i}; % grab the subject
    for c = 1:63 % grab the channel
        for j = 1:size(sub,2) % loop through all trials for one channel 
            trial = sub(:,j);
            trial = trial{1,1};
            fftChannel(j,:) = fft(trial(c,:)); % all trials for one channel
        end
        
        ChannelAvgFFT(c,:) = mean(fftChannel,1); % average all trials together for each channel
        gammaBand(c,:) = ChannelAvgFFT(c, idx); % select the power that corresponds to the gamma band
        avgGammaPower(c,:) = (abs(mean(gammaBand(c,:),2)));

    end
    
    allSubjects_allChannelFFTs{:,i} = (avgGammaPower); 
    
end
    clear avgGammaPower
    clear gammaBand

% TRYING A DIFFERENT METHOD
for i = 1:length(x)
    clear p
    clear f
    clear avgChannelPower
    clear trial
    clear gammaBand
    
    sub = x{:,i};
    for c = 1:63 % loop through the channels
        for t = 1:size(sub,2) % loop through trials
            trial = sub(1,t);
            trial = trial{1,1};
            [p(:,t),f] = pspectrum(trial(c,:),150,'power');
        end
        
        avgChannelPower(:,c) = mean(p,2);
                idx = find(f > 35 & f < 65);
                gammaBand(c,:) = avgChannelPower(idx,c); % select the power that corresponds to the gamma band
                avgGammaPower(c,:) = (abs(mean(gammaBand(c,:),2)));
        
        
        for t = 1:size(sub,2) % loop through trials
            trial = sub(1,t);
            trial = trial{1,1};
            [ps(:,:,t), fs, time]=pspectrum(trial(c,:),150,'spectrogram');
        end
        
 avgChannelSpectrogram(:,:,c) = mean(ps,3);

    end
    
    allSubjects_allChannelPower{:,i} = (avgGammaPower);
    
    
end
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Spectrogram_traditionalMethod_Delay_Example10yearold.mat'), 'ps', '-v7.3');

% plotting the psd
plot(f,pow2db(avgChannelPower))
xlabel('Frequency (Hz)')
ylabel('Power Spectrum (dB)')

dbPower = pow2db(avgGammaPower); 
plot(f,(dbPower))

channelLocations = readtable('H:/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/ourChannels_locations.csv');
channelLocations.Properties.VariableNames{1} = 'labels';

plot_topography('all', avgGammaPower, false, channelLocations)




%% Extract info and put into a table

PowerT = table('Size', [0, 3], 'VariableTypes', {'string', 'cell', 'double'});
PowerT.Properties.VariableNames = {'Subject', 'Channel', 'Power'};


for isub = 1:numSubj
    
    if isempty(x{isub})
        continue
    else
    
   T = table('Size', [63, 3], 'VariableTypes', {'string', 'cell', 'double'});
   T.Properties.VariableNames = {'Subject', 'Channel', 'Power'};


    subjectsPower = allSubjects_allChannelPower{:,isub};
    subject = Subjects(isub); 
    
    T.Subject(1:63) = subject{1};
    T.Channel(1:63) = data.label;
    T.Power = subjectsPower; 
 
    PowerT = [PowerT;T];
    end
    
end

writetable(PowerT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/traditionalEEGanalysis/gammaPower_traditionalMethod_allChannels_Delay_newMethod.csv'));


%% FIXATION

% load in data
addpath(genpath('Functions'));
addpath(genpath(hera('Projects/7TBrainMech/scripts/eeg/toolbox/eeglab14_1_2b')))

eeglab

addpath(('/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/'))
addpath(genpath('Functions'));
addpath(hera('/Projects/7TBrainMech/scripts/fieldtrip-20191127'))
ft_defaults

% load in the x matrix,
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Gamma\Fix\Gamma_Xmatrix_FIX.mat')

% load in subject ID
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Gamma\Fix\Gamma_Subs_FIX.mat')

datapath = hera('/Projects/7TBrainMech/scripts/eeg/Shane/Prep/AfterWhole/ICAwholeClean_homogenize');

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

Fs = 150;
L = 151;
for i = 1:numSubj

    sub = x{:,i};
    
    for j = 1:size(sub,2)
        trial = sub(:,j);
        fftTrial(:,j) = fft(trial); 
    end
    
    avgFFT = mean(fftTrial,2);
    newAvgFFT(:,i) = abs(avgFFT); 
    
end
f = Fs*(0:(L/2))/L;

% the the indices that correspond to the 30-75 hz range

idx = find(f > 30 & f <75); 
gammaBand = newAvgFFT(idx, :); 

avgGammaPower = abs((mean(gammaBand)));


% TRYING A DIFFERENT METHOD
for i = 1:numSubj
    sub = x{:,i};
    for c = 1:63 % loop through the channels
        for t = 1:size(sub,2) % loop through trials
            trial = sub(1,t);
            trial = trial{1,1};
            [p(:,t),f] = pspectrum(trial(c,:),150,'power');
        end
        
        avgChannelPower(:,c) = mean(p,2);
        idx = find(f > 30 & f <75); 
        gammaBand(c,:) = avgChannelPower(idx,c); % select the power that corresponds to the gamma band
        avgGammaPower(c,:) = (abs(mean(gammaBand(c,:),2)));

    end
    
        allSubjects_allChannelPower{:,i} = (avgGammaPower); 

    
end




%% Extract info and put into a table

PowerT = table('Size', [0, 2], 'VariableTypes', {'string', 'double'});
PowerT.Properties.VariableNames = {'Subject', 'Power'};


for isub = 1:numSubj
    
    if isempty(x{isub})
        continue
    else
    
   T = table('Size', [1, 2], 'VariableTypes', {'string', 'double'});
   T.Properties.VariableNames = {'Subject', 'Power'};


    subjectsPower = avgGammaPower(isub);
    subject = Subjects(isub); 
    
    T.Subject(1) = subject{1};
    T.Power = subjectsPower; 
 
    PowerT = [PowerT;T];
    end
    
end

writetable(PowerT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/traditionalEEGanalysis/gammaPower_traditionalMethod_Fix.csv'));



%% Find Power for Individual Channels

% load in the x matrix,
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\IndividualChannelsXmatrix_Fix.mat')

% load in subject ID
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Gamma\Fix\Gamma_Subs_FIX.mat')

clear avgGammaPower
clear gammaBand
clear ChannelAvgFFT

Fs = 150;
L = 151;

f = Fs*(0:(L/2))/L;

% the the indices that correspond to the 30-75 hz range
idx = find(f > 30 & f <75); 

for i = 1:numSubj

    sub = x{:,i}; % grab the subject
    for c = 1:63 % grab the channel
        for j = 1:size(sub,2) % loop through all trials for one channel 
            trial = sub(:,j);
            trial = trial{1,1};
            fftChannel(j,:) = fft(trial(c,:)); % all trials for one channel
        end
        
        ChannelAvgFFT(c,:) = mean(fftChannel,1); % average all trials together for each channel
        gammaBand(c,:) = ChannelAvgFFT(c, idx); % select the power that corresponds to the gamma band
        avgGammaPower(c,:) = (abs(mean(gammaBand(c,:),2)));

    end
    
    allSubjects_allChannelFFTs{:,i} = (avgGammaPower); 
    
end



% TRYING A DIFFERENT METHOD

clear avgGammaPower
clear gammaBand
clear allSubjects_allChannelPower

for i = 1:numSubj
    sub = x{:,i};
    for c = 1:63 % loop through the channels
        for t = 1:size(sub,2) % loop through trials
            trial = sub(1,t);
            trial = trial{1,1};
            [p(:,t),f] = pspectrum(trial(c,:),150,'power');
        end
        
        avgChannelPower(:,c) = mean(p,2);
        idx = find(f > 30 & f <75); 
        gammaBand(c,:) = avgChannelPower(idx,c); % select the power that corresponds to the gamma band
        avgGammaPower(c,:) = (abs(mean(gammaBand(c,:),2)));

    end
    
        allSubjects_allChannelPower{:,i} = (avgGammaPower); 

    
end


%% Extract info and put into a table

PowerT = table('Size', [0, 3], 'VariableTypes', {'string', 'cell', 'double'});
PowerT.Properties.VariableNames = {'Subject', 'Channel', 'Power'};


for isub = 1:numSubj
    
    if isempty(x{isub})
        continue
    else
    
   T = table('Size', [63, 3], 'VariableTypes', {'string', 'cell', 'double'});
   T.Properties.VariableNames = {'Subject', 'Channel', 'Power'};


    subjectsPower = allSubjects_allChannelPower{:,isub};
    subject = Subjects(isub); 
    
    T.Subject(1:63) = subject{1};
    T.Channel(1:63) = data.label;
    T.Power = subjectsPower; 
 
    PowerT = [PowerT;T];
    end
    
end

writetable(PowerT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/traditionalEEGanalysis/gammaPower_traditionalMethod_allChannels_Fix_newMethod.csv'));


%% RESTING STATE

% load in data
addpath(genpath('Functions'));
addpath(genpath(hera('Projects/7TBrainMech/scripts/eeg/toolbox/eeglab14_1_2b')))

eeglab

addpath(('/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/'))
addpath(genpath('Functions'));
addpath(hera('/Projects/7TBrainMech/scripts/fieldtrip-20191127'))
ft_defaults

% load in the x matrix,
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Resting_State_xMatrix.mat')

% load in subject ID
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Resting_State_Subs_RS.mat')

datapath = hera('/Projects/7TBrainMech/scripts/eeg/Shane/Resting_State/AfterWhole/ICAwholeClean_homogenize');

clear setfiles0
clear setfiles

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

clear fftTrial 
clear avgFFT
clear newAvgFFT

Fs = 150;
L = 151;
for i = 1:numSubj

    sub = x{:,i};
    
    for j = 1:size(sub,2)
        trial = sub(:,j);
        fftTrial(:,j) = fft(trial); 
    end
    
    avgFFT = mean(fftTrial,2);
    newAvgFFT(:,i) = abs(avgFFT); 
    
end
f = Fs*(0:(L/2))/L;

% the the indices that correspond to the 30-75 hz range

idx = find(f > 30 & f <75); 
gammaBand = newAvgFFT(idx, :); 

avgGammaPower = abs((mean(gammaBand)));

%% Extract info and put into a table

PowerT = table('Size', [0, 2], 'VariableTypes', {'string', 'double'});
PowerT.Properties.VariableNames = {'Subject', 'Power'};


for isub = 1:numSubj
    
    if isempty(x{isub})
        continue
    else
    
   T = table('Size', [1, 2], 'VariableTypes', {'string', 'double'});
   T.Properties.VariableNames = {'Subject', 'Power'};


    subjectsPower = avgGammaPower(isub);
    subject = Subjects(isub); 
    
    T.Subject(1) = subject{1};
    T.Power = subjectsPower; 
 
    PowerT = [PowerT;T];
    end
    
end

writetable(PowerT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/traditionalEEGanalysis/gammaPower_traditionalMethod_Rest.csv'));



%% Find Power for Individual Channels

% load in the x matrix,
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\IndividualChannelsXmatrix_RestingState.mat')

% load in subject ID
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Subjects_RestingState.mat')

clear avgGammaPower
clear gammaBand
clear ChannelAvgFFT
clear allSubjects_allChannelFFTs
clear fftChannel

Fs = 150;
L = 151;

f = Fs*(0:(L/2))/L;

% the the indices that correspond to the 30-75 hz range
idx = find(f > 30 & f <75); 

for i = 1:numSubj

    sub = x{:,i}; % grab the subject
    for c = 1:63 % grab the channel
        for j = 1:size(sub,2) % loop through all trials for one channel 
            trial = sub(:,j);
            trial = trial{1,1};
            fftChannel(j,:) = fft(trial(c,:)); % all trials for one channel
        end
        
        ChannelAvgFFT(c,:) = mean(fftChannel,1); % average all trials together for each channel
        gammaBand(c,:) = ChannelAvgFFT(c, idx); % select the power that corresponds to the gamma band
        avgGammaPower(c,:) = (abs(mean(gammaBand(c,:),2)));

    end
    
    allSubjects_allChannelFFTs{:,i} = (avgGammaPower); 
    
end


% TRYING A DIFFERENT METHOD

clear avgGammaPower
clear gammaBand
clear allSubjects_allChannelPower

for i = 1:numSubj
    sub = x{:,i};
    for c = 1:63 % loop through the channels
        for t = 1:size(sub,2) % loop through trials
            trial = sub(1,t);
            trial = trial{1,1};
            [p(:,t),f] = pspectrum(trial(c,:),150,'power');
        end
        
        avgChannelPower(:,c) = mean(p,2);
        idx = find(f > 30 & f <75); 
        gammaBand(c,:) = avgChannelPower(idx,c); % select the power that corresponds to the gamma band
        avgGammaPower(c,:) = (abs(mean(gammaBand(c,:),2)));

    end
    
        allSubjects_allChannelPower{:,i} = (avgGammaPower); 

    
end

%% Extract info and put into a table

PowerT = table('Size', [0, 3], 'VariableTypes', {'string', 'cell', 'double'});
PowerT.Properties.VariableNames = {'Subject', 'Channel', 'Power'};


for isub = 1:numSubj
    
    if isempty(x{isub})
        continue
    else
    
   T = table('Size', [63, 3], 'VariableTypes', {'string', 'cell', 'double'});
   T.Properties.VariableNames = {'Subject', 'Channel', 'Power'};


    subjectsPower = allSubjects_allChannelPower{:,isub};
    subject = Subjects(isub); 
    
    T.Subject(1:63) = subject{1};
    T.Channel(1:63) = data.label;
    T.Power = subjectsPower; 
 
    PowerT = [PowerT;T];
    end
    
end

writetable(PowerT, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/traditionalEEGanalysis/gammaPower_traditionalMethod_allChannels_Rest_newMethod.csv'));





