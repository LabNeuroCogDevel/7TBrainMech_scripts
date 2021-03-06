function signal = clean_asr(signal, cutoff, asr_windowlen, asr_stepsize, maxdims, ref_maxbadchannels, ref_tolerances, ref_wndlen, usegpu, varargin)
% Run the ASR method on some high-pass filtered recording.
% Signal = clean_asr(Signal,StandardDevCutoff,WindowLength,BlockSize,MaxDimensions,ReferenceMaxBadChannels,RefTolerances,ReferenceWindowLength)
%
% This is an automated artifact rejection function that ensures that the data contains no events
% that have abnormally strong power; the subspaces on which those events occur are reconstructed 
% (interpolated) based on the rest of the EEG signal during these time periods.
%
% The basic principle is to first find a section of data that represents clean "reference" EEG and
% to compute statistics on there. Then, the function goes over the whole data in a sliding window
% and finds the subspaces in which there is activity that is more than a few standard deviations
% away from the reference EEG (this threshold is a tunable parameter). Once the function has found
% the bad subspaces it will treat them as missing data and reconstruct their content using a mixing
% matrix that was calculated on the clean data.
%
% Notes: 
%   This function by default attempts to use the Statistics toolbox in order to automatically
%   extract calibration data for use by ASR from the given recording. This step is automatically
%   skipped if no Statistics toolbox is present (then the entire recording will be used for
%   calibration, which is fine for mildly contaminated data -- see ReferenceMaxBadChannels below).
%
% In:
%   Signal : continuous data set, assumed to be *zero mean*, e.g., appropriately high-passed (e.g.
%            >0.5Hz or with a 0.5Hz - 1.0Hz transition band)
%
%   Cutoff : Standard deviation cutoff for removal of bursts (via ASR). Data portions whose variance
%            is larger than this threshold relative to the calibration data are considered missing
%            data and will be removed. The most aggressive value that can be used without losing
%            much EEG is 3. For new users it is recommended to at first visually inspect the difference 
%            between the original and cleaned data to get a sense of the removed content at various 
%            levels. A quite conservative value is 5. Default: 5.
%
%
%   The following are detail parameters that usually do not have to be tuned. If you cannot get
%   the function to do what you want, you might consider adapting these better to your data.
%
%   ASR_WindowLength : Length of the statistcs window, in seconds. This should not be much longer 
%                     than the time scale over which artifacts persist, but the number of samples in
%                     the window should not be smaller than 1.5x the number of channels. Default:
%                     max(0.5,1.5*Signal.nbchan/Signal.srate);
%
%   ASR_StepSize : Step size for processing. The reprojection matrix will be updated every this many
%                  samples and a blended matrix is used for the in-between samples. If empty this will
%                  be set the WindowLength/2 in samples. Default: []
%
%   MaxDimensions : Maximum dimensionality to reconstruct. Up to this many dimensions (or up to this 
%                   fraction of dimensions) can be reconstructed for a given data segment. This is
%                   since the lower eigenvalues are usually not estimated very well. Default: 2/3.
%
%   ReferenceMaxBadChannels : If a number is passed in here, the ASR method will be calibrated based
%                             on sufficiently clean data that is extracted first from the recording
%                             that is then processed with ASR. This number is the maximum tolerated
%                             fraction of "bad" channels within a given time window of the recording
%                             that is considered acceptable for use as calibration data. Any data
%                             windows within the tolerance range are then used for calibrating the
%                             threshold statistics. Instead of a number one may also directly pass
%                             in a data set that contains calibration data (for example a minute of
%                             resting EEG) or the name of a data set in the workspace.
%
%                             If this is set to 'off', all data is used for calibration. This will
%                             work as long as the fraction of contaminated data is lower than the
%                             the breakdown point of the robust statistics in the ASR calibration
%                             (50%, where 30% of clearly recognizable artifacts is a better estimate
%                             of the practical breakdown point).
%
%                             A lower value makes this criterion more aggressive. Reasonable range:
%                             0.05 (very aggressive) to 0.3 (quite lax). If you have lots of little
%                             glitches in a few channels that don't get entirely cleaned you might
%                             want to reduce this number so that they don't go into the calibration
%                             data. Default: 0.075.
%                             
%
%   ReferenceTolerances : These are the power tolerances outside of which a channel in a
%                         given time window is considered "bad", in standard deviations relative to
%                         a robust EEG power distribution (lower and upper bound). Together with the
%                         previous parameter this determines how ASR calibration data is be
%                         extracted from a recording. Can also be specified as 'off' to achieve the
%                         same effect as in the previous parameter. Default: [-3.5 5.5].
%
%   ReferenceWindowLength : Granularity at which EEG time windows are extracted
%                           for calibration purposes, in seconds. Default: 1.
%
%   UseGPU : Whether to run on the GPU. This makes sense for offline processing if you have a a card with
%            enough memory and good double-precision performance (e.g., NVIDIA GTX Titan or K20). 
%            Note that for this to work you need to a) have the Parallel Computing toolbox and b) remove 
%            the dummy gather.m file from the path. Default: false
%
% Out:
%   Signal : data set with local peaks removed
%
% Examples:
%   % use the defaults
%   eeg = clean_asr(eeg);
%
%   % use a more aggressive threshold
%   eeg = clean_asr(eeg,2.5);
%
%   % disable subset selection of calibration data (use all data instead)
%   eeg = clean_asr(eeg,[],[],[],[],'off');
%
%   % use a custom calibration measurement (e.g., EEGLAB dataset containing a baseline recording)
%   eeg = clean_asr(eeg,[],[],[],[],mybaseline);
%

% History
% 03/20/2019 Makoto and Chiyuan. Supported 'availableRAM_GB'. GUI switched to GUIDE-made.
% 10/15/2012 Christian. Created.
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2012-10-15

% Copyright (C) Christian Kothe, SCCN, 2012, ckothe@ucsd.edu
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU
% General Public License as published by the Free Software Foundation; either version 2 of the
% License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
% even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% General Public License for more details.
%
% You should have received a copy of the GNU General Public License along with this program; if not,
% write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
% USA

if ~exist('cutoff','var') || isempty(cutoff) cutoff = 5; end
if ~exist('asr_windowlen','var') || isempty(asr_windowlen) asr_windowlen = max(0.5,1.5*signal.nbchan/signal.srate); end % Unit: second.
if ~exist('asr_stepsize','var') || isempty(asr_stepsize) asr_stepsize = []; end
if ~exist('maxdims','var') || isempty(maxdims) maxdims = 0.66; end
if ~exist('ref_maxbadchannels','var') || isempty(ref_maxbadchannels) ref_maxbadchannels = 0.075; end
if ~exist('ref_tolerances','var') || isempty(ref_tolerances) ref_tolerances = [-3.5 5.5]; end
if ~exist('ref_wndlen','var') || isempty(ref_wndlen) ref_wndlen = 1; end
if ~exist('usegpu','var') || isempty(usegpu) usegpu = false; end

if ~isempty(varargin)
    hlp_varargin2struct(varargin,...
    {'availableRAM_GB'}, []);
else
    availableRAM_GB = [];
end

signal.data = double(signal.data);

% first determine the reference (calibration) data
if isnumeric(ref_maxbadchannels) && isnumeric(ref_tolerances) && isnumeric(ref_wndlen)
    disp('Finding a clean section of the data...');
    try
        ref_section = clean_windows(signal,ref_maxbadchannels,ref_tolerances,ref_wndlen); 
    catch e
        disp('An error occurred while trying to identify a subset of clean calibration data from the recording.');
        disp('If this is because do not have EEGLAB loaded or no Statistics toolbox, you can generally');
        disp('skip this step by passing in ''off'' as the ReferenceMaxBadChannels parameter.');
        disp('Error details: ');
        hlp_handleerror(e,1);
        disp('Falling back to using the entire data for calibration.')
        ref_section = signal;
    end
elseif strcmp(ref_maxbadchannels,'off') || strcmp(ref_tolerances,'off') || strcmp(ref_wndlen,'off')
    disp('Using the entire data for calibration (reference parameters set to ''off'').')
    ref_section = signal;
elseif ischar(ref_maxbadchannels) && isvarname(ref_maxbadchannels)
    disp('Using a user-supplied data set in the workspace.');
    ref_section = evalin('base',ref_maxbadchannels);
elseif all(isfield(ref_maxbadchannels,{'data','srate','chanlocs'}))
    disp('Using a user-supplied clean section of data.');
    ref_section = ref_maxbadchannels; 
else
    error('Unsupported value for argument ref_maxbadchannels.');
end

% calibrate on the reference data
disp('Estimating calibration statistics; this may take a while...');
if exist('hlp_diskcache','file')
    state = hlp_diskcache('filterdesign',@asr_calibrate,ref_section.data,ref_section.srate,cutoff);
else
    state = asr_calibrate(ref_section.data, ref_section.srate, cutoff, [], [], [], [], [], [], [], 'availableRAM_GB', availableRAM_GB);
    % state = asr_calibrate(X, srate, cutoff, blocksize, B, A, window_len, window_overlap, max_dropout_fraction, min_clean_fraction, 
end
clear ref_section;

if isempty(asr_stepsize)
    asr_stepsize = floor(signal.srate*asr_windowlen/2); end

% extrapolate last few samples of the signal
sig = [signal.data bsxfun(@minus,2*signal.data(:,end),signal.data(:,(end-1):-1:end-round(asr_windowlen/2*signal.srate)))];
% process signal using ASR
[signal.data,state] = asr_process(sig,signal.srate,state,asr_windowlen,asr_windowlen/2,asr_stepsize,maxdims,availableRAM_GB,usegpu);
% shift signal content back (to compensate for processing delay)
signal.data(:,1:size(state.carry,2)) = [];
