function [ EEG, data ] = w_notch_filter( notchHz, notchWidth, EEG, data )
%PREPROC Summary of this function goes here
%   Detailed explanation goes here
notchHz = str2num(notchHz);
notchWidth = str2num(notchWidth);
for i = 1 : size(notchHz,2)
    EEG.data = notch_filter(EEG, notchHz(1,i),notchWidth);
end

end

