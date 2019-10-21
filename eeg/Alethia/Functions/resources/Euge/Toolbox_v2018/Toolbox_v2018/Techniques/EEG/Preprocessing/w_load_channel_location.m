function [ EEG, data ] = w_load_channel_location( node_file_name, EEG, data)
%Loads channels euclidean coordinates for channels from a .node file. The
%file's structure should be have as many rows as channels and six columns:
%   column 1: x
%   column 2: y
%   column 3: z
%   column 4: size
%   column 5: color
%   column 6: label
%Only columns 1 to 3 will be used.

EEG = load_electrode_location_into_EEG(node_file_name,EEG,data);