function [ EEG, data ] = w_plot_average_erps_band( condition_1, condition_2, roi_struct_filename, roi_struct_name, erps_files_prefix, frequency_bands, title_names, p_value, colorPvalue, color1, color2, statmethod, prefix_file_name, EEG, data )
%Load erps mat and the associated variables of its calculation. Gets the
%ERPS matrix for each frequency band and calls PlotCollapsedERPSBySubject
%to plot average frequency for each conditions with statistical analyses.

% w_ PARAMETERS
% roi_struct_filename = 'EmpathyForPain_P9_Bipolar.mat';
% tf_variables_filename = 'RetentionFacesInputsNewFFTBaseline.mat'; % Calculted parameters from time frequency analysis from other function (w_process_erps)
% tf_maps_filename = 'ERPS\NEWFFT_baseline\Retention_Faceserps.mat'; %Calculated time frequency charts from other function (w_process_erps)
tf_maps_filename = fullfile(data.path, 'ERPS', [erps_files_prefix 'ERPS_complete.mat']);
tf_variables_filename = fullfile(data.path, 'ERPS', [erps_files_prefix 'ERPS_outputs_complete.mat']);
frequency_bands = str2num(frequency_bands);%[1 4; 4 8; 8 13; 13 30; 30 45; 45 80; 80 150];
title_names = cellstr(strsplit(title_names));%{'delta','theta','alpha','beta','lowgamma','highgamma','broadband'};

%FUNCTION PARAMETERS
% condition_1 = 'Binding';
% condition_2 = 'Features';

p_value = str2num(p_value);%0.05;
% colorPvalue = 'g';
color1 = str2num(color1);%[1 0 0]; %red
color2 = str2num(color2);%[0 0 1]; %blue

if isequal(prefix_file_name,'')
    prefix_file_name = fullfile(data.path, 'ERPS', 'average_band');
end

%----------RUN------------------------------------------------------------
f = load(fullfile(data.path,'ERPS',roi_struct_filename), roi_struct_name);
roi_struct = f.(roi_struct_name);

%loads erpsMapsByTrialByROIs erpsByROIs from calculated time frequency charts from other function (w_process_erps)
load(tf_maps_filename)

%loads freqs timesout mbase g from calculted parameters from time frequency analysis from other function (w_process_erps)
load(tf_variables_filename)

totalERPS = erpsMapsByTrialByROIs;

roi_count  = size(roi_struct,2);
%epochLine = -4200;
condition_1_indexes = calculate_epochs_mask(strsplit(condition_1), EEG);
condition_2_indexes = calculate_epochs_mask(strsplit(condition_2), EEG);
frequencies = freqs(:);

for f = 1 : size(frequency_bands,1)
    initFreq = frequency_bands(f,1);
    endFreq = frequency_bands(f,2);

    if initFreq < frequencies(1)
        initFreqRow = 1;
    else
        initFreqRow = interp1(frequencies,1:length(frequencies),initFreq);
    end

    if endFreq > frequencies(length(frequencies))
        endFreqRow = length(frequencies);
    else
        endFreqRow = interp1(frequencies,1:length(frequencies),endFreq);
    end

    for i = 1 : roi_count
        erps_by_trial = totalERPS(i).erpsByTrial;
        roiERPSCond1 = erps_by_trial(:,:,condition_1_indexes);
        roiERPSCond2 = erps_by_trial(:,:,condition_2_indexes);

        cond1mat = roiERPSCond1(initFreqRow:endFreqRow,:,:);
        cond2mat = roiERPSCond2(initFreqRow:endFreqRow,:,:);

        titleName = [title_names{f} '-' roi_struct(i).name];
        plot_collapsed_ERPS_by_subject(cond1mat,cond2mat,timesout,statmethod,p_value,prefix_file_name,titleName,color1,color2,colorPvalue);
    end
end

display('DONE w_plot_average_erps_band')