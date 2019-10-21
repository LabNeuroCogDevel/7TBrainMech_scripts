function plot_ERPS_for_3_conditions_and_difference(condition_1,condition_2, condition_3, files_prefix, path_to_save,roi_struct,tlimits,cycles,frequency_range,alpha,fdr_correct,weighted_significance,surroundings_weight,scale,tlimits_for_baseline,basenorm,erps_max,mark_times, EEG, data)
%Calculates ERPS for three conditions and saves to output files.
%Then calculates ERPS difference between all combinations of the three
%conditions (1 vs 2, 1 vs 3 and 2 vs 3).

%INPUTS:
%EEG: Full EEG with all the conditions.

%condition_1: string - name of condition_1
%condition_2: string - name of condition_2
%condition_3: string - name of condition_3

%files_prefix: string - prefix that will be appended to the condition and
%                     type of comparison as file name

%path_to_save: string - folder where files will be saved
%roi_struct: struct of anatomic rois
%frequency analysis inputs:
%tlimits: vector of 2 values that indicate epoch temporal value in ms
%cycles: if wavelet analysis is to be used - vector of two values, e.g. [3
%           0.5]; if FFT is to be used then assign 0.
%frequency_range: vector of two values that indicate lowest frequency and
%                           highest frequency values of the range to be considered, e.g. [1 150]
%alpha: statistical significance value to be considered, e.g. p = 0.01. If
%           p = 0 no statistical analysis will be performed
%fdr_correct: 1: for false detection rate to be used, 0: no to perform false
%                  detection rate
%weighted_significance: 0: if no weighted significance is to be used, 1: if
%                                   it will be used
%surroundings_weight: weight of surrounding significance to be considered
%                                 (only valid if weightedSignificance = 1)
%scale: string - 'abs' for absolute scale, 'log' for logarithmic scale
%tlimits_for_baseline: vector of two values that indicate time limits in ms for
%                               baseline, e.g. [-500 0]
%basenorm: type of basenormalization 0: divisive baseline; 1:standard deviation
%erpsmax: vector of limits in colormap, e.g. [-15 15]
%marktimes: vector with times that showed be marked in plot


%OUTPUTS:
%files with the time frequency calculation for the three conditions, the
%figures and the comparison of every combination of pairs of conditions


%ERPS FOR FACES AND WORDS (+ DIFF)
%eeglab needs to be loaded already
EEG_condition_1 = filter_epochs(strsplit(condition_1), EEG);
EEG_condition_2 = filter_epochs(strsplit(condition_2), EEG);
EEG_condition_3 = filter_epochs(strsplit(condition_3), EEG);
%Condition1
%calculate ERPS
titleName = fullfile(path_to_save, [files_prefix '-' condition_1]);
[erpsMapsByTrialByROIsCond1,erpsByROIsCond1, meanERPSMapCond1, RCond1, PbootCond1, RbootCond1, ERPCond1, freqsCond1, timesoutCond1, mbaseCond1, maskerspCond1, maskitcCond1, gCond1,PboottrialsCond1] = plot_ERPS_by_ROI_2(roi_struct,EEG_condition_1,tlimits,cycles,frequency_range,alpha,fdr_correct,titleName,weighted_significance,surroundings_weight,scale,tlimits_for_baseline,basenorm,erps_max,mark_times);

eval(['save ' titleName 'ERPS.mat erpsMapsByTrialByROIsCond1 erpsByROIsCond1']);   
eval(['save ' titleName 'ERPSOutputs.mat freqsCond1 timesoutCond1 mbaseCond1 gCond1']); 


%Condition2
%calculate ERPS
titleName = fullfile(path_to_save, [files_prefix '-' condition_2]);
[erpsMapsByTrialByROIsCond2,erpsByROIsCond2, meanERPSMapCond2, RCond2, PbootCond2, RbootCond2, ERPCond2, freqsCond2, timesoutCond2, mbaseCond2, maskerspCond2, maskitcCond2, gCond2,PboottrialsCond2] = plot_ERPS_by_ROI_2(roi_struct,EEG_condition_2,tlimits,cycles,frequency_range,alpha,fdr_correct,titleName,weighted_significance,surroundings_weight,scale,tlimits_for_baseline,basenorm,erps_max,mark_times);

eval(['save ' titleName 'ERPS.mat erpsMapsByTrialByROIsCond2 erpsByROIsCond2']);   
eval(['save ' titleName 'ERPSOutputs.mat freqsCond2 timesoutCond2 mbaseCond2 gCond2']); 

%Condition3
%calculate ERPS
titleName = fullfile(path_to_save, [files_prefix '-' condition_3]);
[erpsMapsByTrialByROIsCond3,erpsByROIsCond3, meanERPSMapCond3, RCond3, PbootCond3, RbootCond3, ERPCond3, freqsCond3, timesoutCond3, mbaseCond3, maskerspCond3, maskitcCond3, gCond3,PboottrialsCond3] = plot_ERPS_by_ROI_2(roi_struct,EEG_condition_3,tlimits,cycles,frequency_range,alpha,fdr_correct,titleName,weighted_significance,surroundings_weight,scale,tlimits_for_baseline,basenorm,erps_max,mark_times);

eval(['save ' titleName 'ERPS.mat erpsMapsByTrialByROIsCond3 erpsByROIsCond3']);   
eval(['save ' titleName 'ERPSOutputs.mat freqsCond3 timesoutCond3 mbaseCond3 gCond3']); 


%Diff: 1 - 2 
file_2_save = [files_prefix '-' condition_1 '-' condition_2];
plot_ERPS_for_diff_conditions(erpsByROIsCond1,erpsByROIsCond2,file_2_save,path_to_save,gCond2,PbootCond2,ERPCond2,mbaseCond2,freqsCond2,timesoutCond2,roi_struct);

%Diff: 1 - 3 
file_2_save = [files_prefix '-' condition_1 '-' condition_3];
plot_ERPS_for_diff_conditions(erpsByROIsCond1,erpsByROIsCond3,file_2_save,path_to_save,gCond3,PbootCond3,ERPCond3,mbaseCond3,freqsCond3,timesoutCond3,roi_struct);

%Diff: 2 - 3 
file_2_save = [files_prefix '-' condition_2 '-' condition_3];
plot_ERPS_for_diff_conditions(erpsByROIsCond2,erpsByROIsCond3,file_2_save,path_to_save,gCond2,PbootCond2,ERPCond2,mbaseCond2,freqsCond2,timesoutCond2,roi_struct);
