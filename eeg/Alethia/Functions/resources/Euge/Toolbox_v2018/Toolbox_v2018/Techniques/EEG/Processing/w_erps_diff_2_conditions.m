function [ EEG, data ] = w_erps_diff_2_conditions( condition_1, condition_2, roi_struct_filename, roi_struct_name, files_prefix, tlimits, cycles, frequency_range, alpha, fdr_correct, weighted_significance, surroundings_weight, scale, basenorm, tlimits_for_baseline, erps_max, mark_times, path_to_save, EEG, data )

if isequal(path_to_save,'')
    path_to_save = fullfile(data.path, 'ERPS', 'FFTComplete');
end
if ~exist(path_to_save, 'dir')
  mkdir(path_to_save);
end

f = load(fullfile(data.path,'ERPS',roi_struct_filename), roi_struct_name);
roi_struct = f.(roi_struct_name);

tlimits = str2num(tlimits);%[-250 1000];
cycles = str2num(cycles);%0; %FFT
frequency_range = str2num(frequency_range);%[0 150];
alpha = str2num(alpha);%0.05;
fdr_correct = str2num(fdr_correct);%0;
%si quiero reduccion de significancia = 1 sino = 0;
weighted_significance = str2num(weighted_significance);%0;
surroundings_weight = str2num(surroundings_weight);%0.5;
% scale = 'abs';
basenorm = str2num(basenorm);%1; % 0: divisive baseline; 1: standard deviation
tlimits_for_baseline = str2num(tlimits_for_baseline);%[-250 0];
erps_max = str2num(erps_max);%[-15 15];
mark_times = str2num(mark_times);%[];

%----RUN-------------------------------------------------------------------

plot_ERPS_for_2_conditions_and_difference(condition_1,condition_2,files_prefix, path_to_save,roi_struct,tlimits,cycles,frequency_range,alpha,fdr_correct,weighted_significance,surroundings_weight,scale,tlimits_for_baseline,basenorm,erps_max,mark_times, EEG, data)

display('DONE w_erps_diff_2_conditions')
