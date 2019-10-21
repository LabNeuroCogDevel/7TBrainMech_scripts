function [ EEG, data ] = w_filter_epochs( epochs, EEG, data )
%PREPROC Summary of this function goes here
%   Detailed explanation goes here
epochs = strsplit(epochs);
data.selected_epoched_EEG = filter_epochs(epochs, EEG);
return