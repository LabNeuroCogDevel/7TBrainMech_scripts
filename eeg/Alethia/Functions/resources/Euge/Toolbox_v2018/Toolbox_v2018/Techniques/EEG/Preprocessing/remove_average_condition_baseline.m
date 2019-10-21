function [EEG] = remove_average_condition_baseline(EEG,time_range)
%The baselines of all epochs in EEG.data are averaged and then substracted 
%from the baseline of each trial. This procedure is performed by channel. 
%INPUTS: 
%   * EEG: struct with the data on which an average condition baseline
%       removal will be performed.
%   * time_range: a vector of 2 values, indicating the initial and final
%       times of the considered baseline. The time range
%       must be contained within the original epoch time frame. 
%       Must be set in miliseconds.
%OUTPUTS:
%   * EEG: the struct with average condition baseline.
intial_time = time_range(1);
final_time = time_range(2);

%get corresponding indexes of the times vector for the desired time range 
intial_indx = round(interp1(EEG.times,1:length(EEG.times),intial_time));
final_indx = round(interp1(EEG.times,1:length(EEG.times),final_time));

%check that time_range is contained within the original epoch
%initial value
assert(~isnan(intial_indx), ['Cannot perform average condition baseline. Value not contained in original set. Initial value = '  num2str(intial_time)]);
%final value
assert(~isnan(final_indx), ['Cannot perform average condition baseline. Value not contained in original set. Final value = '  num2str(final_time)]);

for ch = 1 : size(EEG.data,1)    
    zero_timepoint_indx = interp1(EEG.times,1:EEG.pnts,0);
    avg_baseline = mean(squeeze(EEG.data(ch,1:zero_timepoint_indx-1,:)),2);
    vec_to_substract = zeros(EEG.pnts,1);
    vec_to_substract(1:length(avg_baseline)) = avg_baseline;    
    EEG.data(ch,:,:) = squeeze(EEG.data(ch,:,:)) - repmat(vec_to_substract,[1,size(EEG.data,3)]);    
end