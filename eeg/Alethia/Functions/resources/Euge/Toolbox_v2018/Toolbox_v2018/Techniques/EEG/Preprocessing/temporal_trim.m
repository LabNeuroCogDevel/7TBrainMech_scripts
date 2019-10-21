function EEG = temporal_trim(EEG,time_range)
%Trims the epochs of EEG to a new time range.
%INPUTS:
%   * EEG: EEG struct with a loaded set
%   * time_range: a vector with 2 values that specify the intial and final
%       time range of the new epoch. Values outside the range established
%       will be trimmed. Time range must be set in miliseconds.
%OUTPUT: 
%   * EEG: EEG struct with the epochs' new time range, and related variables
%       within it coherently set.


intial_time = time_range(1);
final_time = time_range(2);

%get corresponding indexes of the times vector for the desired time range 
intial_indx = round(interp1(EEG.times,1:length(EEG.times),intial_time));
final_indx = round(interp1(EEG.times,1:length(EEG.times),final_time));

%check that time_range is contained within the original epoch
%initial value
if isnan(intial_indx)
    msg = ['Cannot trim epoch. Value not contained in original set. Initial value = '  num2str(intial_time)];
    error(msg)
elseif isnan(final_indx) %final value
    msg = ['Cannot trim epoch. Value not contained in original set. Final value = ' num2str(final_time)];
    error(msg)
end

EEG.times = EEG.times(intial_indx:final_indx);
EEG.pnts = length(EEG.times);
EEG.data = EEG.data(:,intial_indx:final_indx,:);

%set to seconds
EEG.xmax = EEG.times(end)/1000;
EEG.xmin = EEG.times(1)/1000;