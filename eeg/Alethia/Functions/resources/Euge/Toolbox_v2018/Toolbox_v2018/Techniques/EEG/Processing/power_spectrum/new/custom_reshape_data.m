function [data, frames] = custom_reshape_data(data, frames)
data = squeeze(data);
if min(size(data)) == 1
    if (rem(length(data),frames) ~= 0)
        error('Length of data vector must be divisible by frames.');
    end
    data = reshape(data, frames, length(data)/frames);
else
    frames = size(data,1);
end