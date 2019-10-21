function [ EEG, data ] = w_plot_wsmi_distance( filename, data_range, kernel, fs, taus, EEG, data )
clc

addpath(genpath('C:\Program Files\MATLAB\R2010a\toolbox\stats'))

%PARAMETERS
task_name = 'Retention_Faces';
condition1 = 'Features'; %file name associated to calculated wSMI matrix
condition2 = 'Binding'; %file name associated to calculated wSMI matrix
%OJO - idealmente aca se levantaría una única matriz de conectividad y se
%eligirían las condiciones, es decir, los trials

taus = [1 2 4 8 16 32];
wsmi_path = ''; %local path to connectivity matrices
fileName = 'Farinelli_Retention_Faces';

%load electrode coordinates and calculate distance between them
labelfileNameFaces = 'Labels\Farinelli_AnatomicCoordinates.txt';
fid = fopen(labelfileNameFaces,'r');
data = textscan(fid, '%d %s %f %f %f');
fclose(fid);

electrodes.x = data{1,3};
electrodes.y = data{1,4};
electrodes.z = data{1,5};

electrodeDistances = CalculateElectrodeDistance(electrodes,0,'');

p_value = 0.01;
distanceThresholdPlot = 0;

channelNr = length(electrodes.x);
path2save = 'wSMI\1\Distance\'; %OJO - local path that must exist

for i = 1 : size(taus,2)
    completeFileName = [path2save fileName '-Distance-tau-' int2str(taus(1,i))];
    tau = i;    
    PlotWSMIDistance(Task,condition1,condition2,tau,path,fileName,channelNr,electrodeDistances,p_value,distanceThreshold,completeFileName);
end

display('DONE Retention Faces')