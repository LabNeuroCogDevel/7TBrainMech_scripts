function [ ] = display_text_file( path )
%SAVE_FILE Summary of this function goes here
%   Detailed explanation goes here
file_path = fullfile(path,'Toolbox_log.txt');
if exist(file_path, 'file') == 2
    fid = fopen(file_path,'r');
else
    fid = fopen(file_path,'a+');
end


%# read text file lines as cell array of strings
str = textscan(fid, '%s', 'Delimiter','\n'); str = str{1};
fclose(fid);

%# GUI with multi-line editbox
hFig = figure('Menubar','none', 'Toolbar','none','Name','View Log','NumberTitle','off');
uicontrol(hFig, 'Style','edit', 'FontSize',9, ...
    'Min',0, 'Max',2, 'HorizontalAlignment','left', ...
    'Units','normalized', 'Position',[0 0 1 1], ...
    'String',str,'Interpreter','None');

end

