function [ ] = log_to_file( name, inputs, arguments, path )
%SAVE_FILE Summary of this function goes here
%   Detailed explanation goes here
line = [datestr(now, 'yyyy-mm-dd HH:MM:SS') ' ' name];
for i = 1:length(inputs)
    line = [line ', ' inputs{i} ': ' arguments{i}];
end
file_path = fullfile(path,'Toolbox_log.txt');
if exist(file_path, 'file') == 2
    fileID = fopen(file_path,'a');
else
    fileID = fopen(file_path,'w');
end
fprintf(fileID,'%s\n', line);
fclose(fileID);
end

