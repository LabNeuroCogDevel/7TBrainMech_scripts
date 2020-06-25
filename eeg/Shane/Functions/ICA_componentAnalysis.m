function [] = ICA_componentAnalysis()


path_data = hera('Projects/7TBrainMech/scripts/eeg/Shane/Prep/AfterWhole/ICAwholeClean_homogenize/');
CleanICApath = hera('Projects/7TBrainMech/scripts/eeg/Shane/Prep/AfterWhole/ICA_components_for_Analysis/');

% added to code to redo the 20 subjects who needed to be pushed through 
redo = [10129];
for i = 1: length(redo) 
    file(i,:) = sprintf('Projects/7TBrainMech/scripts/eeg/Shane/Prep/AfterWhole/ICAwholeClean_homogenize/%d', redo(i));
    EEGfileNames(i,:) = dir(hera([file(i,:) '*.set']));
end

% Select ICA

EEGfileNames = dir([path_data '/*.set']);

for currentEEG = 1:size(EEGfileNames,1)
    filename = [EEGfileNames(currentEEG).name];
selecompICA
end

