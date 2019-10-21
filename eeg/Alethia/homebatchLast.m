%%
% Select components to remove
addpath(genpath('Functions'));
addpath(genpath('Functions/resources/Euge/Toolbox_v2018'))

path_data = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/ICAwhole/');
CleanICApath = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/ICAwholeClean/');

%% added to code to redo the 20 subjects who needed to be pushed through 
redo = [11688 11701 11681];
for i = 1: length(redo) 
    file(i,:) = sprintf('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/ICAwhole/%d', redo(i));
    EEGfileNames(i,:) = dir(hera([file(i,:) '*.set']));
end

%% Select ICA

EEGfileNames = dir([path_data '/*.set']);

for currentEEG = 1:size(EEGfileNames,1)
    filename = [EEGfileNames(currentEEG).name];
selecompICA
end

%%
% Clean epochs to remove
path_data = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/ICAwholeClean/');
epoch_folder =  hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/epoch/');
epoch_rj_marked_folder = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/epochclean/');

%% added to code to be pushed through manually 
% redo = [11733 11299 11451 11750 11631 11669 11742 11645 11715 10173 11672 11675 11543 11630 11771 11664 10997 11634 11741 10644 11708 11661];
% for i = 1: length(redo) 
%     file(i,:) = sprintf('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/ICAwholeClean/%d', redo(i));
%     EEGfileNames(i,:) = dir(hera([file(i,:) '*_icapru.set']));
% end

%%
EEGfileNames = dir([path_data, '/*_icapru.set']);

revisar = {};
for currentEEG = 1:size(EEGfileNames,1)
    filename = [EEGfileNames(currentEEG).name];
    inputfile = [path_data,filename];
revisar{currentEEG} = epochlean(inputfile,epoch_folder,epoch_rj_marked_folder);
end
% save revisar revisar

%% Epoching small 
clear all
close all
%% paths
addpath(genpath('Functions'));
% addpath(hera('Projects/7TBrainMech/scripts/eeg/toolbox/eeglab14_1_2b'))
%% files
folder = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/epochclean/');
%% added to code to run manually 
% redo = [11640];
% for i = 1: length(redo) 
%     file(i,:) = sprintf('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/epochclean/%d', redo(i));
%     setfiles0(i,:) = dir(hera([file(i,:) '*ICA_icapru_epochs_rj.set']));
% end
%%

filter = [folder,'*ICA_icapru_epochs_rj.set'];
setfiles0 = dir(filter);
setfiles = {};
for ica = 1:length(setfiles0)
setfiles{ica,1} = fullfile(folder, setfiles0(ica).name); % cell array with EEG file names
% setfiles = arrayfun(@(x) fullfile(folder, x.name), setfiles(~[setfiles.isdir]),folder, 'Uni',0); % cell array with EEG file names
end


%% Homogenize Chanloc
datapath = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/epochclean');
% datapath = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/epochclean');
outpath = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/epochclean_homogenize');

%% added to code to run manually 
% redo = [11543 10997 10173 11661 11673 11640];
% for i = 1: length(redo) 
%     file(i,:) = sprintf('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/epochclean/%d', redo(i));
%     setfiles0(i,:) = dir(hera([file(i,:) '*.set']));
% end
%%
setfiles0 = dir([datapath,'/*.set']);
setfiles = {};
for epo = 1:length(setfiles0)
setfiles{epo,1} = fullfile(datapath, setfiles0(epo).name); % cell array with EEG file names
% setfiles = arrayfun(@(x) fullfile(folder, x.name), setfiles(~[setfiles.isdir]),folder, 'Uni',0); % cell array with EEG file names
end

correction_cap_location = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Functions/resources/ELchanLoc.ced');
for i = 1:length(setfiles)
    homogenizeChanLoc(setfiles{i},correction_cap_location,outpath)
end
%% Create Epochs for each condition
% Select epochs
outpath = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/PermutEpoch');
datapath = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/epochclean');
setfiles0 = dir([datapath,'/*.set']);
setfiles = {};
for epo = 1:length(setfiles0)
setfiles{epo,1} = fullfile(datapath, setfiles0(epo).name); % cell array with EEG file names
% setfiles = arrayfun(@(x) fullfile(folder, x.name), setfiles(~[setfiles.isdir]),folder, 'Uni',0); % cell array with EEG file names
end

mdirect{1}.mark = '1';mdirect{1}.outputdir = outpath;mdirect{1}.name = 'ITI';
mdirect{2}.mark =  '2';mdirect{2}.outputdir =  outpath;mdirect{2}.name = 'Cue';
mdirect{3}.mark =  '-3';mdirect{3}.outputdir = outpath;mdirect{3}.name = 'DotL_n3';
mdirect{4}.mark =  '3';mdirect{4}.outputdir = outpath;mdirect{4}.name = 'DotR_p3';
mdirect{5}.mark =  '4';mdirect{5}.outputdir = outpath;mdirect{5}.name = 'Delay';
mdirect{6}.mark =  '-5';mdirect{6}.outputdir = outpath;mdirect{6}.name = 'MVSL_n5';
mdirect{7}.mark =  '5';mdirect{7}.outputdir = outpath;mdirect{7}.name = 'MVSR_p5';
wind = [-0.20  1];
misssubj = cell(size(setfiles,1),size(mdirect,2)+1);
for currentEEG = 1:size(setfiles,1)
    missingbycond = extraepochs(setfiles{currentEEG},mdirect ,wind);
    
    [a,b,c] = fileparts(setfiles{currentEEG});
    misssubj{1,1} = b;
    misssubj{1,2} = missingbycond{1,1};
    misssubj{1,3} = missingbycond{1,2};
    misssubj{1,4} = missingbycond{1,3};
    misssubj{1,5} = missingbycond{1,4};
    misssubj{1,6} = missingbycond{1,5};
    misssubj{1,7} = missingbycond{1,6};
    misssubj{1,7} = missingbycond{1,7};
    save epocasXtipo misssubj
end

%% Permutaciones
addpath(genpath('resources/permutaciones'));
datapath = hera('/Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/homogenize_PermutEpoch');
Resultados_folder = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Results/ERPs');
% Firth part generates the grand average for each condition
condition{1} = 'ITI';
condition{2} = 'Cue';
condition{3} = 'DotR_p3';
condition{4} = 'DotL_n3';
condition{5} = 'Delay';
condition{6} = 'MVSR_p5';
condition{7} = 'MVSL_n5';
for i=1:length(condition)
outputname = [condition{i},'_GAv'];
grandaverage(datapath,outputname,condition{i})
end

%%
%Rois Parietal (R y L), Frontal lateral (R y L), partially invented
cfg.rois{1}=[5 6 7]; %left-frontal
cfg.rois{2}=[40 39 38]; %right-frontal
cfg.rois{3}=[22 23 31]; %left-parietal
cfg.rois{4}=[31 59 58]; %right-parietal
cfg.rois{5}=[cfg.rois{1} cfg.rois{2} cfg.rois{3} cfg.rois{4}]; % All
cfg.rois{6} = [32 23 59 31 24 60 58];

%%
% % %% 3 DotR_p3 Vs -3 DotL_n3
%DATASET UNO
cfg.orig_dir_uno=datapath;cfg.orig_dir_dos=datapath;
cfg.set_uno_filename=[condition{3},'_GAv.set']; cfg.set_name1=[condition{3},'_GAv'];
%DATA SET DOS
cfg.set_dos_filename=[condition{4},'_GAv.set']; cfg.set_name2=[condition{4},'_GAv'];
cfg.gruping = 'off';
%nombre figuras
cfg.name_fig=['ROI1',cfg.set_name1, 'Vs' cfg.set_name2];
cfg.outputpath = [Resultados_folder,'/',cfg.set_name1, 'Vs' cfg.set_name2, '/'];
mkdir(cfg.outputpath)
Permutame( cfg );
close all
%% 5 Vs -5
cfg.set_uno_filename=[condition{4},'_GAv.set']; cfg.set_name1=[condition{4},'_GAv'];
%DATA SET DOS
cfg.set_dos_filename=[condition{7},'_GAv.set']; cfg.set_name2=[condition{7},'_GAv'];
%nombre figuras
cfg.name_fig=['ROI',cfg.set_name1, 'Vs' cfg.set_name2];
cfg.outputpath = [Resultados_folder,'/',cfg.set_name1, 'Vs' cfg.set_name2, '/'];
mkdir(cfg.outputpath)
Permutame( cfg );
close all
%% -3 Vs -5
%DATASET UNO
cfg.set_uno_filename=[condition{3},'_GAv.set']; cfg.set_name1=[condition{3},'_GAv'];
%DATA SET DOS
cfg.set_dos_filename=[condition{6},'_GAv.set']; cfg.set_name2=[condition{6},'_GAv'];
%nombre figuras
cfg.name_fig=['ROI',cfg.set_name1, 'Vs' cfg.set_name2];
cfg.outputpath = [Resultados_folder,'/',cfg.set_name1, 'Vs' cfg.set_name2, '/'];
mkdir(cfg.outputpath)
Permutame( cfg )
close all
%% 3 Vs 5
%DATASET UNO
cfg.set_uno_filename=[condition{4},'_GAv.set']; cfg.set_name1=[condition{4},'_GAv'];
%DATA SET DOS
cfg.set_dos_filename=[condition{7},'_GAv.set']; cfg.set_name2=[condition{7},'_GAv'];
%nombre figuras
cfg.name_fig=['ROI',cfg.set_name1, 'Vs' cfg.set_name2];
cfg.outputpath = [Resultados_folder,'/',cfg.set_name1, 'Vs' cfg.set_name2, '/'];
mkdir(cfg.outputpath)
Permutame( cfg )
close all
%% 2 Vs 4
%DATASET UNO
cfg.set_uno_filename=[condition{2},'_GAv.set']; cfg.set_name1=[condition{2},'_GAv'];
%DATA SET DOS
cfg.set_dos_filename=[condition{5},'_GAv.set']; cfg.set_name2=[condition{5},'_GAv'];
%nombre figuras
cfg.name_fig=['ROI',cfg.set_name1, 'Vs' cfg.set_name2];
cfg.outputpath = [Resultados_folder,'/',cfg.set_name1, 'Vs' cfg.set_name2, '/'];
mkdir(cfg.outputpath)
Permutame( cfg )
close all
