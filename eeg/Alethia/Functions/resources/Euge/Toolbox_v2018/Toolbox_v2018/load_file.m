function [ handles ] = load_file( file_name, path, handles )
%SAVE_FILE Summary of this function goes here
%   Detailed explanation goes here
load(fullfile(path, file_name));
[pathstr,~,~] = fileparts(which('Toolbox'));
data.toolbox_path = pathstr;
handles.dat = data;
end

