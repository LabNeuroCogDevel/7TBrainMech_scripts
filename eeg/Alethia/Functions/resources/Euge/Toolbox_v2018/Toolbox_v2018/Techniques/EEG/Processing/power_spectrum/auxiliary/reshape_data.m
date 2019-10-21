function [data, frames] = reshape_data(data, frames)
%EEGLAB 14.1.1b embedded function in newtimef.m
data = squeeze(data);
if min(size(data)) == 1
    if (rem(length(data),frames) ~= 0)
        error('Length of data vector must be divisible by frames.');
    end
    data = reshape(data, frames, length(data)/frames);
else
    frames = size(data,1);
end