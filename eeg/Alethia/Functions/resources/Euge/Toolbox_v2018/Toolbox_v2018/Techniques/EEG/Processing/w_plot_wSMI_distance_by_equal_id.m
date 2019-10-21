function [EEG, data] = w_plot_wSMI_distance_by_equal_id(task_name, condition_1, condition_2, taus, file_name, label_file_name, wsmi_path, p_value, threshold, path_to_save, EEG, data)
%addpath(genpath('C:\Program Files\MATLAB\R2010a\toolbox\stats'))

%PARAMETERS
% task_name = 'Retention_Faces';
% condition_1 = 'Features'; %file name associated to calculated wSMI matrix
% condition_2 = 'Binding'; %file name associated to calculated wSMI matrix
%OJO - idealmente aca se levantaría una única matriz de conectividad y se
%eligirían las condiciones, es decir, los trials
if isequal(wsmi_path,'')
    wsmi_path = data.path;
end

taus = str2num(taus);%[1 2 4 8 16 32];
% wsmi_path = ''; %local path to connectivity matrices
% file_name = 'Farinelli_Retention_Faces';

%load electrode coordinates and calculate distance between them
% label_file_name = 'Labels\Farinelli_AnatomicCoordinates.txt';
label_file_name = fullfile(data.path, label_file_name);
fid = fopen(label_file_name,'r');
label_data = textscan(fid, '%d %s %f %f %f');
fclose(fid);

electrodes.x = label_data{1,3};
electrodes.y = label_data{1,4};
electrodes.z = label_data{1,5};

electrodeDistances = CalculateElectrodeDistance(electrodes,0,'');

p_value = str2num(p_value);%0.01;
threshold = str2num(threshold);%0;

channelNr = length(electrodes.x);
% path_to_save = 'wSMI\1\Distance\'; %OJO - local path that must exist
if isequal(path_to_save,'')
    path_to_save = fullfile(data.path, 'wSMI', 'Distance');
end
if ~exist(path_to_save, 'dir')
    mkdir(path_to_save);
end

for i = 1 : size(taus,2)
%for i = 1 : 1
    completeFileName = fullfile(path_to_save, [file_name '-Distance-tau-' int2str(taus(1,i))]);
    tau = taus(i);
    PlotWSMIDistanceByEqualD(task_name,condition_1,condition_2,tau,wsmi_path,file_name,channelNr,electrodeDistances,p_value,threshold,completeFileName);
end

display('DONE Retention Faces')