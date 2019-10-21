function [ ] = save_file( handles )
%SAVE_FILE Summary of this function goes here
%   Detailed explanation goes here
data = handles.dat;
save(fullfile(handles.dat.project_path, handles.dat.project_file_name), 'data');
end

