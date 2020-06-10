restoredefaultpath
addpath('Functions')
addpath(genpath('Functions/resources/Euge/Toolbox_v2018/Toolbox_v2018'))

% 'Toolbox' looks into folders and pulls from functions.txt
%  Functions/resources/Euge/Toolbox_v2018/Toolbox_v2018/Toolbox.m
%  Functions/resources/Euge/Toolbox_v2018/Toolbox_v2018/Techniques/EEG/functions.txt
%     Calculate and plot ERSP by channel (EEG)|w_erps_by_channel_EEG| ...
%  Functions/resources/Euge/Toolbox_v2018/Toolbox_v2018/Techniques/EEG/Processing/w_erps_by_channel_EEG.m
%  sets parent to empty and calls
%  Functions/resources/Euge/Toolbox_v2018/Toolbox_v2018/Techniques/EEG/Processing/w2_erps_by_channel_EEG.m
% GUI:
%  run('Toolbox.m')
%   EEG; File -> path to data -> 
%   /Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Prep/AfterWhole/epochcleanTF
%   Function groups: processing
%   select function: Calculate and plot ERSP by channel (EEG)
%   select empyt first row
%   edit button
%     condition_1: 4  (delay)
%     cycle: 0=forier 1+ cycles for wavelet
%     freq_range: 50 b/c downsampled to 100hz. but 70 okay anyway
%     alpha: 0.05 (calc stats, not used yet?) 
%    save_as: /Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Results/TF/test
% Command:
% Functions/resources/Euge/Toolbox_v2018/Toolbox_v2018/Techniques/EEG/Processing/w_erps_by_channel_EEG.m
% Functions/resources/Euge/Toolbox_v2018/Toolbox_v2018/Techniques/EEG/Processing/w2_erps_by_channel_EEG.m


%% to remove data that does have the correct epoch you want 

% files = dir(hera('/Projects/7TBrainMech/scripts/eeg/Shane/Prep/AfterWhole/epochclean_homogenize/*.set'));
% 
% for i = 1: length(files)
%  
%     filename = fullfile(files(i).folder,files(i).name);
%     EEG = pop_loadset(filename);
% 
% 
%    event =  EEG.epoch.eventtype;
%    hasEvent = arrayfun(@(x) ismember('2',x.eventtype{1}), EEG.epoch);
%    totalEvents = sum(hasEvent); 
%    
%    if totalEvents < 2
%        warning('%s was moved to folder entitled SubjectsWithoutEpoch2', filename);
%        movefile(filename, hera('/Projects/7TBrainMech/scripts/eeg/Shane/Prep/AfterWhole/SubjectsWithoutEpoch2/')); 
%        
%    end 
% end

%% run the toolbox
condition_1='4'; % delay
condition_2='1'; %ISI
cycles='0';
freq_range='4 70';
alpha='0.05';
fdr='none';
scale='log';
basenorm='off';
erps_max='';
path_to_save = hera('/Projects/7TBrainMech/scripts/eeg/Shane/Results/TF/Delay');

% data setup for w2_erps_by_channel_EEG
data.path_to_files = hera('/Projects/7TBrainMech/scripts/eeg/Shane/Prep/AfterWhole/ICAwholeClean_homogenize');
data.path_to_save = hera('/Projects/7TBrainMech/scripts/eeg/Shane/Results/TF/Delay');
% done in w_erps_by_channel_EEG.m but never used
% data.parent_directory = ''

EEG = [];
[data] = w2_erps_by_channel_EEG(condition_1,condition_2,cycles,freq_range,alpha,fdr,scale,basenorm,erps_max,path_to_save,EEG,data);

% imagesc(squeeze(s_erps{2}(1,:,:)))
