function [ EEG, data ] = w_print_electrode_information(file_name,EEG,data)
%Writes to a file the electrodes' information. Each electrode is a row, and
%the columns represent:
%   column 1: electrode number
%   column 2: label
%   column 3: x
%   column 4: y
%   column 5: z

print_electrode_location(file_name,EEG,data);
