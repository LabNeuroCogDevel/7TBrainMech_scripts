
%% load in data
addpath(genpath('Functions'));
addpath(genpath(hera('Projects/7TBrainMech/scripts/eeg/toolbox/eeglab14_1_2b')))

eeglab

addpath(('/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/'))
addpath(genpath('Functions'));
addpath(hera('/Projects/7TBrainMech/scripts/fieldtrip-20191127'))
ft_defaults

% load in the x matrix, the ERPs, the Baselined ERPs, and the Mean Squared amplitude 
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\AudSteadyState\XmatrixWithallSubjects_includesPreStim.mat')
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\AudSteadyState\allSubjectERPs_includesPreStim.mat')
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\AudSteadyState\allSubjectERPs_baselinedERPs.mat')
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\AudSteadyState\allSubject_MeanSquaredAmp.mat')

% load in spontanous activity
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\AudSteadyState\allSubject_Spontaneous.mat')

% load in subject ID
load('H:\Projects\7TBrainMech\scripts\eeg\Shane\AudSteadyState\SubjectsinXmatrix.mat')

%% Evoked 
% plot a young and old representation of ERPs 
cap_location = 'H:\Projects\7TBrainMech\scripts\fieldtrip-20191127\template\layout\biosemi64.lay';
if ~exist(cap_location, 'file'), error('cannot find file for 128 channel cap: %s', cap_location), end

cfg.layout = cap_location;
cfg.fontsize = 6;
cfg.showlabels = 'yes';
cfg.showoutline = 'yes';
cfg.interactive = 'yes';
ft_multiplotER(cfg,baselinedERPs{1})










