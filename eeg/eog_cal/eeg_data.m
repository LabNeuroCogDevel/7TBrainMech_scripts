function [subj_struct] = eeg_data(taskname, channels, varargin)
%EEG_DATA get raw eeg into matlab datas tructure
%  USAGE: d = eeg_data('ANTI', {'Status','horz_eye'})
%         cal = eeg_data('eyecal',{'Status','horz_eye'})
%   provide a task, a lit of channels, and optionaly a processing level
%  outputs a struct with field id, and d (data matrix)

ft_test % check if we have fieldtrip

root='/Volumes/Hera/Raw/EEG/7TBrainMech/';

%% get all files like *Taskname*
bdf_files = dir(fullfile(root,'1*_2*',['*' taskname '*.bdf'])); %TODO: preproc level
bdf_files = arrayfun(@(x) fullfile(x.folder,x.name), bdf_files, 'UniformOutput',0);
if length(bdf_files) < 1; error(['no files matching task' taskname]); end

%% extract luna_date (5 digits _ 8 digits)
subjids = cellfun(@(x) regexp(x,'\d{5}+_\d{8}+','once','match'),bdf_files,'UniformOutput',0);

%% read in all files
fprintf('reading in %d %s files, pulling channels: %s\n', length(bdf_files), taskname,...
    strjoin(channels));
subj_struct = cellfun(@(x) bdf_read_chnl(x,channels), bdf_files);

%% assign ids
[subj_struct.id ] = subjids{:};

end

