function [EEG,data] = w_custom_erps_by_channel_EEG(condition_1,condition_2,cycles,freq_range,alpha,fdr,scale,basenorm,erps_max,prefix_to_save,EEG,data)

data.parent_directory = '';
[data] = w2_custom_erps_by_channel_EEG(condition_1,condition_2,cycles,freq_range,alpha,fdr,scale,basenorm,erps_max,prefix_to_save,data);