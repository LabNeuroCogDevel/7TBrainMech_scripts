function [subj_struct] = eeg_data(taskname, channels, varargin)
%EEG_DATA get raw eeg into matlab data structure
%  eeg_data(taskname|fileglob|abspath|cell, channels[, 'subjs', {subj, subj}])
%   provide 
%     1) a way to find .bdf eeg files (taskname, abs path, glob, or cell of any of those)
%         *  use "#cal" for all calibration names, #mgs for all mgs task
%         *  use cell for multiple tasks, see `cals=` example usage
%     2) a cell of channels names
%         * 'horz_eye' gives uniform name to left (EX3,EG3,FT7) and right eye
%         * 'Status' is adjusted to get tiggers 0-255
%     3) optionaly: 'subjs', subjlist cell
%        eeg_data('MGS',ch,'subjs',{'11676','10195_20180201'})
%   outputs a struct array with Fs, id, file, and channel data fields
%
%  USAGE:
%   ch={'Status','horz_eye'};
%   d = eeg_data('ANTI', ch,'subjs',{'11676','10195_20180201'});
%   cal = eeg_data('eyecal',ch)
%   cals = eeg_data({'eyecal','EOG'},ch)
%   cal11451 = eeg_data('11451_2*_EOGCalib.bdf',ch)
%    N.B. 
%    * "#cal" as taskname searches all calibration variations, see find_bdf.m
%    * "#mgs" as taskname searches all mgs tasks             , see find_bdf.m
%    * for just a file list use find_bdf
%       find_bdf('1*MGS')
%    * for one file, use  bdf_read_chnl(file, ch [,header])
%       f=hera('Raw/EEG/7TBrainMech/11676_20180821/11676_20180821_ANTI.bdf');
%       % on rhea: '/Volumes/Hera/Raw/EEG/7TBrainMech/11676_20180821/11676_20180821_ANTI.bdf'
%       bdf_read_chnl(f, ch)
%    * for all header information use fieldtrip:
%       h=ft_read_header(f)

%% be helpful when given bad params
if(nargin<1), help('eeg_data'); error("need task and channels"); end
if(nargin==1)
    warning(['no channels given! returning subject list instead of data; '...
        'consider find_bdf(''' taskname ''')']);
    subj_struct = find_bdf(taskname,varargin{:});
    return
end

ft_test % check if we have fieldtrip

%% get all files
bdf_files = find_bdf(taskname,varargin{:});
if length(bdf_files) < 1; error(['no files matching task ' taskname]); end

%% extract luna_date (5 digits _ 8 digits)
subjids = cellfun(@(x) regexp(x,'\d{5}+_\d{8}+','once','match'),bdf_files,'UniformOutput',0);

%% read in all files
if isa(taskname,'cell'), taskname=strjoin(taskname); end
fprintf('reading in %d %s files, pulling channels: %s\n', length(bdf_files), taskname,...
    strjoin(channels));
subj_struct = cellfun(@(x) bdf_read_chnl(x,channels), bdf_files);

%% assign ids
[subj_struct.id ] = subjids{:};

end

