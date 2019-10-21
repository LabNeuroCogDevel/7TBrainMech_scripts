function [ EEG, data ] = w_smi( filename, data_range, kernel, fs, taus, EEG, data )
%PREPROC Summary of this function goes here
%   Detailed explanation goes here
selected_epoched_EEG = EEG;
if isfield(data, 'selected_epoched_EEG')
    selected_epoched_EEG = data.selected_epoched_EEG;
end
data_range = str2num(data_range);
kernel = str2num(kernel);
fs = str2num(fs);
taus = str2num(taus);

start_point = find(abs(selected_epoched_EEG.times - data_range(1)*1000) < 1000/fs);
end_point = find(abs(selected_epoched_EEG.times - data_range(2)*1000) < 1000/fs);
if ~start_point
    start_point = 1;
end
if ~end_point
    end_point = length(selected_epoched_EEG.times);
end

data_range = start_point(1):end_point(1);

[sym ,~ ] = symbolic_transfer(selected_epoched_EEG.data,kernel, fs, taus, data_range,data.path,filename);

mutual_information(data.path, filename, sym, taus);

return