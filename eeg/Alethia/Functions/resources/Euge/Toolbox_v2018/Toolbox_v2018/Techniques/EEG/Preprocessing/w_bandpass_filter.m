function [ EEG, data ] = w_bandpass_filter( bandpassRange, EEG, data )
%PREPROC Summary of this function goes here
%   Detailed explanation goes here
bandpassRange = str2num(bandpassRange);
figure
EEG = pop_eegfiltnew(EEG, bandpassRange(1,1), bandpassRange(1,2), 3380, 0, [], 1);

end

