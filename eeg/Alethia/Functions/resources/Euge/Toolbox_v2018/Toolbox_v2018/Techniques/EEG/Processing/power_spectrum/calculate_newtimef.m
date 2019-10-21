% newtimef() - Return estimates and plots of mean event-related (log) spectral
%           perturbation (ERSP) and inter-trial coherence (ITC) events across
%           event-related trials (epochs) of a single input channel time series.
%
%         * Also can compute and statistically compare transforms for two time
%           series. Use this to compare ERSP and ITC means in two conditions.
%
%         * Uses either fixed-window, zero-padded FFTs (fastest), or wavelet
%           0-padded DFTs. FFT uses Hanning tapers; wavelets use (similar) Morlet
%           tapers.
%
%         * For the wavelet and FFT methods, output frequency spacing
%           is the lowest frequency ('srate'/'winsize') divided by 'padratio'.
%           NaN input values (such as returned by eventlock()) are ignored.
%
%         * If 'alpha' is given (see below), permutation statistics are computed
%           (from a distribution of 'naccu' surrogate data trials) and
%           non-significant features of the output plots are zeroed out
%           and plotted in green.
%
%         * Given a 'topovec' topo vector and 'elocs' electrode location file,
%           the figure also shows a topoplot() view of the specified scalp map.
%
%         * Note: Left-click on subplots to view and zoom in separate windows.
%
% Usage with single dataset:
%        >> [ersp,itc,powbase,times,freqs,erspboot,itcboot] = ...
%                  newtimef(data, frames, epochlim, srate, cycles,...
%                       'key1',value1, 'key2',value2, ... );
%
% Example to compare two condition (channel 1 EEG versus ALLEEG(2)):
%        >> [ersp,itc,powbase,times,freqs,erspboot,itcboot] = ...
%                  newtimef({EEG.data(1,:,:) ALLEEG(2).data(1,:,:)},
%                       EEG.pnts, [EEG.xmin EEG.xmax]*1000, EEG.srate, cycles);
% NOTE:
%        >> timef details  % presents more detailed argument information
%                          % Note: version timef() also computes multitaper transforms
%
% Required inputs:    Value                                 {default}
%       data        = Single-channel data vector (1,frames*ntrials), else 
%                     2-D array (frames,trials) or 3-D array (1,frames,trials).
%                     To compare two conditions (data1 versus data2), in place of 
%                     a single data matrix enter a cell array {data1 data2}
%       frames      = Frames per trial. Ignored if data are 2-D or 3-D.  {750}
%       tlimits     = [mintime maxtime] (ms).  Note that these are the time limits 
%                     of the data epochs themselves, NOT A SUB-WINDOW TO EXTRACT 
%                     FROM THE EPOCHS as is the case for pop_newtimef(). {[-1000 2000]}
%       Fs          = data sampling rate (Hz)  {default: read from icadefs.m or 250}
%       varwin      = [real] indicates the number of cycles for the time-frequency 
%                        decomposition {default: 0}
%                     If 0, use FFTs and Hanning window tapering.  
%                     If [real positive scalar], the number of cycles in each Morlet 
%                        wavelet, held constant across frequencies.
%                     If [cycles cycles(2)] wavelet cycles increase with 
%                        frequency beginning at cycles(1) and, if cycles(2) > 1, 
%                        increasing to cycles(2) at the upper frequency,
%                      If cycles(2) = 0, use same window size for all frequencies 
%                        (similar to FFT when cycles(1) = 1)
%                      If cycles(2) = 1, cycles do not increase (same as giving
%                         only one value for 'cycles'). This corresponds to a pure
%                         wavelet decomposition, same number of cycles at each frequency.
%                      If 0 < cycles(2) < 1, cycles increase linearly with frequency:
%                         from 0 --> FFT (same window width at all frequencies) 
%                         to 1 --> wavelet (same number of cycles at all frequencies).
%                     The exact number of cycles in the highest frequency window is 
%                     indicated in the command line output. Typical value: 'cycles', [3 0.5]
%
%    Optional inter-trial coherence (ITC) Type:
%       'itctype'   = ['coher'|'phasecoher'|'phasecoher2'] Compute either linear
%                     coherence ('coher') or phase coherence ('phasecoher').
%                     Originall called 'phase-locking factor' {default: 'phasecoher'}
%
%    Optional detrending:
%       'detrend'   = ['on'|'off'], Linearly detrend each data epoch   {'off'}
%       'rmerp'     = ['on'|'off'], Remove epoch mean from data epochs {'off'}
%
%    Optional FFT/DFT parameters:
%       'winsize'   = If cycles==0: data subwindow length (fastest, 2^n<frames);
%                     If cycles >0: The *longest* window length to use. This
%                     determines the lowest output frequency. Note: this parameter 
%                     is overwritten when the minimum frequency requires
%                     a longer time window {default: ~frames/8}
%       'timesout'  = Number of output times (int<frames-winframes). Enter a
%                     negative value [-S] to subsample original times by S.
%                     Enter an array to obtain spectral decomposition at
%                     specific times (Note: The algorithm finds the closest time
%                     point in data; this could give a slightly unevenly spaced
%                     time array                                    {default: 200}
%       'padratio'  = FFT-length/winframes (2^k)                    {default: 2}
%                     Multiplies the number of output frequencies by dividing
%                     their spacing (standard FFT padding). When cycles~=0,
%                     frequency spacing is divided by padratio.
%       'maxfreq'   = Maximum frequency (Hz) to plot (& to output, if cycles>0)
%                     If cycles==0, all FFT frequencies are output. {default: 50}
%                     DEPRECATED, use 'freqs' instead,and never both.
%       'freqs'     = [min max] frequency limits. {default [minfreq 50],
%                     minfreq being determined by the number of data points,
%                     cycles and sampling frequency.
%       'nfreqs'    = number of output frequencies. For FFT, closest computed
%                     frequency will be returned. Overwrite 'padratio' effects
%                     for wavelets. {default: use 'padratio'}
%       'freqscale' = ['log'|'linear'] frequency scale. {default: 'linear'}
%                     Note that for obtaining 'log' spaced freqs using FFT,
%                     closest correspondant frequencies in the 'linear' space
%                     are returned.
%       'verbose'   = ['on'|'off'] print text {'on'}
%       'subitc'    = ['on'|'off'] subtract stimulus locked Inter-Trial Coherence
%                     (ITC) from x and y. This computes an 'intrinsic' coherence
%                     of x and y not arising directly from common phase locking 
%                     to experimental events. See notes.    {default: 'off'}
%       'wletmethod' = ['dftfilt'|'dftfilt2'|'dftfilt3'] Wavelet type to use.
%                     'dftfilt2' -> Morlet-variant wavelets, or Hanning DFT.
%                     'dftfilt3' -> Morlet wavelets.  See the timefreq() function 
%                     for more detials {default: 'dftfilt3'}
%       'cycleinc'    ['linear'|'log'] mode of cycles increase when [min max] cycles 
%                     are provided in 'cycle' parameter. Applies only to 
%                     'wletmethod','dftfilt'  {default: 'linear'}
%       
%   Optional baseline parameters:
%       'baseline'  = Spectral baseline end-time (in ms). NaN --> no baseline is used. 
%                     A [min max] range may also be entered
%                     You may also enter one row per region for baseline
%                     e.g. [0 100; 300 400] considers the window 0 to 100 ms and
%                     300 to 400 ms This parameter validly defines all baseline types 
%                     below. Again, [NaN] Prevent baseline subtraction.
%                     {default: 0 -> all negative time values}. 
%       'powbase'   = Baseline spectrum to log-subtract {default|NaN -> from data}
%       'commonbase' = ['on'|'off'] use common baseline when comparing two 
%                     conditions {default: 'on'}.
%       'basenorm'  = ['on'|'off'] 'on' normalize baseline in the power spectral
%                     average; else 'off', divide by the average power across 
%                     trials at each frequency (gain model). {default: 'off'}
%       'trialbase' = ['on'|'off'|'full'] perform baseline (normalization or division 
%                     above in single trial instead of the trial average. Default
%                     if 'off'. 'full' is an option that perform single
%                     trial normalization (or simple division based on the
%                     'basenorm' input over the full trial length before
%                     performing standard baseline removal. It has been
%                     shown to be less sensitive to noisy trials in Grandchamp R, 
%                     Delorme A. (2011) Single-trial normalization for event-related 
%                     spectral decomposition reduces sensitivity to noisy trials. 
%                     Front Psychol. 2:236.
%
%    Optional time warping parameter: 
%       'timewarp'  = [eventms matrix] Time-warp amplitude and phase time-
%                     courses(following time/freq transform but before 
%                     smoothing across trials). 'eventms' is a matrix 
%                     of size (all_trials,epoch_events) whose columns
%                     specify the epoch times (latencies) (in ms) at which 
%                     the same series of successive events occur in each 
%                     trial. If two data conditions, eventms should be 
%                     [eventms1;eventms2] --> all trials stacked vertically.
%      'timewarpms' = [warpms] optional vector of event times (latencies) (in ms) 
%                     to which the series of events should be warped.
%                     (Note: Epoch start and end should not be declared
%                     as eventms or warpms}. If 'warpms' is absent or [], 
%                     the median of each 'eventms' column will be used;
%                     If two datasets, the grand medians of the two are used.
%     'timewarpidx' = [plotidx] is an vector of indices telling which of 
%                     the time-warped 'eventms' columns (above) to show with 
%                     vertical lines. If undefined, all columns are plotted. 
%                     Overwrites the 'vert' argument (below) if any.
%
%    Optional permutation parameters:
%       'alpha'     = If non-0, compute two-tailed permutation significance 
%                      probability level. Show non-signif. output values 
%                      as green.                              {default: 0}
%       'mcorrect'  = ['none'|'fdr'] correction for multiple comparison
%                     'fdr' uses false detection rate (see function fdr()).
%                     Not available for condition comparisons. {default:'none'} 
%       'pcontour'  = ['on'|'off'] draw contour around significant regions
%                     instead of masking them. Not available for condition 
%                     comparisons. {default:'off'} 
%       'naccu'     = Number of permutation replications to accumulate {200}
%       'baseboot'  = permutation baseline subtract (1 -> use 'baseline';
%                                                    0 -> use whole trial
%                                            [min max] -> use time range) 
%                     You may also enter one row per region for baseline,
%                     e.g. [0 100; 300 400] considers the window 0 to 100 ms 
%                     and 300 to 400 ms. {default: 1}
%       'boottype'  = ['shuffle'|'rand'|'randall'] 'shuffle' -> shuffle times 
%                     and trials; 'rand' -> invert polarity of spectral data 
%                     (for ERSP) or randomize phase (for ITC); 'randall' -> 
%                     compute significances by accumulating random-polarity 
%                     inversions for each time/frequency point (slow!). Note
%                     that in the previous revision of this function, this
%                     method was called 'bootstrap' though it is actually 
%                     permutation {default: 'shuffle'}
%       'condboot'  = ['abs'|'angle'|'complex'] to compare two conditions,
%                     either subtract ITC absolute values ('abs'), angles
%                     ('angles'), or complex values ('complex'). {default: 'abs'}
%       'pboot'     = permutation power limits (e.g., from newtimef()) {def: from data}
%       'rboot'     = permutation ITC limits (e.g., from newtimef()). 
%                     Note: Both 'pboot' and 'rboot' must be provided to avoid 
%                     recomputing the surrogate data! {default: from data}
%
%    Optional Scalp Map:
%       'topovec'   = Scalp topography (map) to plot              {none}
%       'elocs'     = Electrode location file for scalp map       {none}
%                     Value should be a string array containing the path
%                     and name of the file.  For file format, see
%                         >> topoplot example
%       'chaninfo'    Passed to topoplot, if called.
%                     [struct] optional structure containing fields 
%                     'nosedir', 'plotrad', and/or 'chantype'. See these 
%                     field definitions above, below.
%                     {default: nosedir +X, plotrad 0.5, all channels}
%
%     Optional Plotting Parameters:
%       'scale'     = ['log'|'abs'] visualize power in log scale (dB) or absolute
%                     scale. {default: 'log'}
%       'plottype'  = ['image'|'curve'] plot time/frequency images or traces
%                     (curves, one curve per frequency). {default: 'image'}
%       'plotmean'  = ['on'|'off'] For 'curve' plots only. Average all
%                     frequencies given as input. {default: 'on'}
%       'highlightmode'  = ['background'|'bottom'] For 'curve' plots only,
%                     display significant time regions either in the plot background
%                     or under the curve.
%       'plotersp'  = ['on'|'off'] Plot power spectral perturbations    {'on'}
%       'plotitc'   = ['on'|'off'] Plot inter-trial coherence           {'on'}
%       'plotphasesign' = ['on'|'off'] Plot phase sign in the inter trial coherence {'on'}
%       'plotphaseonly' = ['on'|'off'] Plot ITC phase instead of ITC amplitude {'off'}
%       'erspmax'   = [real] set the ERSP max. For the color scale (min= -max) {auto}
%       'itcmax'    = [real] set the ITC image maximum for the color scale {auto}
%       'hzdir'     = ['up' or 'normal'|'down' or 'reverse'] Direction of
%                     the frequency axes {default: as in icadefs.m, or 'up'}
%       'ydir'      = ['up' or 'normal'|'down' or 'reverse'] Direction of
%                     the ERP axis plotted below the ITC {as in icadefs.m, or 'up'}
%       'erplim'    = [min max] ERP limits for ITC (below ITC image)       {auto}
%       'itcavglim' = [min max] average ITC limits for all freq. (left of ITC) {auto}
%       'speclim'   = [min max] average spectrum limits (left of ERSP image)   {auto}
%       'erspmarglim' = [min max] average marginal ERSP limits (below ERSP image) {auto}
%       'title'     = Optional figure or (brief) title {none}. For multiple conditions
%                     this must contain a cell array of 2 or 3 title strings.
%       'marktimes' = Non-0 times to mark with a dotted vertical line (ms)     {none}
%       'linewidth' = Line width for 'marktimes' traces (thick=2, thin=1)      {2}
%       'axesfont'  = Axes text font size                                      {10}
%       'titlefont' = Title text font size                                     {8}
%       'vert'      = [times_vector] -> plot vertical dashed lines at specified times
%                     in ms. {default: none}
%       'newfig'    = ['on'|'off'] Create new figure for difference plots {'on'}
%       'caption'   = Caption of the figure {none}
%       'outputformat' = ['old'|'plot'] for compatibility with script that used the 
%                        old output format, set to 'old' (mbase in absolute amplitude (not
%                        dB) and real itc instead of complex itc). 'plot' returns
%                        the plotted result {default: 'plot'}
% Outputs:
%            ersp   = (nfreqs,timesout) matrix of log spectral diffs from baseline
%                     (in dB log scale or absolute scale). Use the 'plot' output format
%                     above to output the ERSP as shown on the plot.
%            itc    = (nfreqs,timesout) matrix of complex inter-trial coherencies.
%                     itc is complex -- ITC magnitude is abs(itc); ITC phase in radians
%                     is angle(itc), or in deg phase(itc)*180/pi.
%          powbase  = baseline power spectrum. Note that even, when selecting the 
%                     the 'trialbase' option, the average power spectrum is
%                     returned (not trial based). To obtain the baseline of
%                     each trial, recompute it manually using the tfdata
%                     output described below.
%            times  = vector of output times (spectral time window centers) (in ms).
%            freqs  = vector of frequency bin centers (in Hz).
%         erspboot  = (nfreqs,2) matrix of [lower upper] ERSP significance.
%          itcboot  = (nfreqs) matrix of [upper] abs(itc) threshold.
%           tfdata  = optional (nfreqs,timesout,trials) time/frequency decomposition 
%                      of the single data trials. Values are complex.
%
% Plot description:
%   Assuming both 'plotersp' and 'plotitc' options are 'on' (= default). 
%   The upper panel presents the data ERSP (Event-Related Spectral Perturbation) 
%   in dB, with mean baseline spectral activity (in dB) subtracted. Use 
%   "'baseline', NaN" to prevent timef() from removing the baseline. 
%   The lower panel presents the data ITC (Inter-Trial Coherence). 
%   Click on any plot axes to pop up a new window (using 'axcopy()')
%   -- Upper left marginal panel presents the mean spectrum during the baseline 
%      period (blue), and when significance is set, the significance threshold 
%      at each frequency (dotted green-black trace).
%   -- The marginal panel under the ERSP image shows the maximum (green) and 
%      minimum (blue) ERSP values relative to baseline power at each frequency.
%   -- The lower left marginal panel shows mean ITC across the imaged time range 
%      (blue), and when significance is set, the significance threshold (dotted 
%      green-black).  
%   -- The marginal panel under the ITC image shows the ERP (which is produced by 
%      ITC across the data spectral pass band).
%
% Authors: Arnaud Delorme, Jean Hausser from timef() by Sigurd Enghoff, Scott Makeig
%          CNL / Salk Institute 1998- | SCCN/INC, UCSD 2002-
%
% See also: timefreq(), condstat(), newcrossf(), tftopo()

%    Deprecated Multitaper Parameters: [not included here]
%       'mtaper'    = If [N W], performs multitaper decomposition.
%                      (N is the time resolution and W the frequency resolution;
%                      maximum taper number is 2NW-1). Overwrites 'winsize' and 'padratio'.
%                     If [N W K], forces the use of K Slepian tapers (if possible).
%                      Phase is calculated using standard methods.
%                      The use of mutitaper with wavelets (cycles>0) is not
%                      recommended (as multiwavelets are not implemented).
%                      Uses Matlab functions DPSS, PMTM.      {no multitaper}

%    Deprecated time warp keywords (working?)
%      'timewarpfr' = {{[events], [warpfr], [plotidx]}} Time warp amplitude and phase
%                     time-courses (after time/freq transform but before smoothingtimefreqfunc
%                     across trials). 'events' is a matrix whose columns specify the
%                     epoch frames [1 ... end] at which a series of successive events
%                     occur in each trial. 'warpfr' is an optional vector of event
%                     frames to which the series of events should be time locked.
%                     (Note: Epoch start and end should not be declared as events or
%                     warpfr}. If 'warpfr' is absent or [], the median of each 'events'
%                     column will be used. [plotidx] is an optional vector of indices
%                     telling which of the warpfr to plot with vertical lines. If
%                     undefined, all marks are plotted. Overwrites 'vert' argument,
%                     if any. [Note: In future releases, 'timewarpfr' will be deprecated
%                     in favor of 'timewarp' using latencies in ms instead of frames].

%    Deprecated original time warp keywords (working?)
%       'timeStretchMarks' = [(marks,trials) matrix] Each trial data will be
%                     linearly warped (after time/freq. transform) so that the
%                     event marks are time locked to the reference frames
%                     (see timeStretchRefs). Marks must be specified in frames
%       'timeStretchRefs' = [1 x marks] Common reference frames to all trials.
%                     If empty or undefined, median latency for each mark will be used.boottype
%       'timeStretchPlot' = [vector] Indicates the indices of the reference frames
%                     (in StretchRefs) should be overplotted on the ERSP and ITC.
%EEGLAB 14.1.1b
function [P,R,mbase,timesout,freqs,Pboot,Rboot,alltfX] = calculate_newtimef( data, frames, tlimits, Fs, varwin, scale,frange,alpha,bnorm,fdr);

%varwin,winsize,g.timesout,g.padratio,g.maxfreq,g.topovec,g.elocs,g.alpha,g.marktimes,g.powbase,g.pboot,g.rboot)

% Read system (or directory) constants and preferences:
% ------------------------------------------------------
icadefs % read local EEGLAB constants: HZDIR, YDIR, DEFAULT_SRATE, DEFAULT_TIMLIM

% if ~exist('HZDIR'), HZDIR = 'up'; end; % ascending freqs
% if ~exist('YDIR'), YDIR = 'up'; end;   % positive up
% 
% if YDIR == 1, YDIR = 'up'; end;        % convert from [-1|1] as set in icadefs.m  
% if YDIR == -1, YDIR = 'down'; end;     % and read by other plotting functions

% Constants set here:
% ------------------
% ERSP_CAXIS_LIMIT = 0;           % 0 -> use data limits; else positive value
% giving symmetric +/- caxis limits.
MIN_ABS          = 1e-8;        % avoid division by ~zero

% Command line argument defaults:
% ------------------------------
DEFAULT_NWIN	= 200;		% Number of windows = horizontal resolution
DEFAULT_VARWIN	= 0;		% Fixed window length or fixed number of cycles.
% =0: fix window length to that determined by nwin
% >0: set window length equal to varwin cycles
%     Bounded above by winsize, which determines
%     the min. freq. to be computed.

DEFAULT_OVERSMP	= 2;		% Number of times to oversample frequencies
%DEFAULT_TITLE	= '';		% Figure title (no default)
%DEFAULT_ELOC    = 'chan.locs';	% Channel location file
DEFAULT_ALPHA   = NaN;		% Percentile of bins to keep
%DEFAULT_MARKTIME= NaN;

% Font sizes:
%AXES_FONT       = 10;           % axes text FontSize
%TITLE_FONT      =  8;

DEFAULT_WINSIZE = max(pow2(nextpow2(frames)-3),4);
DEFAULT_PAD = max(pow2(nextpow2(DEFAULT_WINSIZE)),4);

data = reshape_data(data, frames);
trials = size(data,ndims(data));

% [ g timefreqopts ] = finputcheck(varargin, ...
%     {'boottype'      'string'    {'shuffle','rand','randall'}    'shuffle'; ...
%     'condboot'      'string'    {'abs','angle','complex'}       'abs'; ...
%     'winsize'       'integer'      [0 Inf]  DEFAULT_WINSIZE; ...
%     'pad'           'real'      []          DEFAULT_PAD; ...
%     'timesout'      'integer'   []          DEFAULT_NWIN; ...
%     'padratio'      'integer'   [0 Inf]     DEFAULT_OVERSMP; ...
%     'alpha'         'real'      [0 0.5]     DEFAULT_ALPHA; ...
%     'marktimes'     'real'      []          DEFAULT_MARKTIME; ...
%     'powbase'       'real'      []          NaN; ...
%     'pboot'         'real'      []          NaN; ...
%     'rboot'         'real'      []          NaN; ...
%     'plotersp'      'string'    {'on','off'} 'off'; ...
%     'plotamp'       'string'    {'on','off'} 'on'; ...
%     'plotitc'       'string'    {'on','off'} 'off'; ...
%     'detrend'       'string'    {'on','off'} 'off'; ...
%     'rmerp'         'string'    {'on','off'} 'off'; ...
%     'basenorm'      'string'    {'on','off'} 'off'; ...
%     'commonbase'    'string'    {'on','off'} 'on'; ...
%     'baseline'      'real'      []           0; ...
%     'baseboot'      'real'      []           1; ...
%     'linewidth'     'integer'   [1 2]        2; ...
%     'naccu'         'integer'   [1 Inf]      200; ...
%     'mtaper'        'real'      []           []; ...
%     'maxfreq'       'real'      [0 Inf]      DEFAULT_MAXFREQ; ...
%     'freqs'         'real'      [0 Inf]      [0 DEFAULT_MAXFREQ]; ...
%     'cycles'        'integer'   []           []; ...
%     'nfreqs'        'integer'   []           []; ...
%     'freqscale'     'string'    []           'linear'; ...
%     'vert'          'real'      []           [];  ...
%     'newfig'        'string'    {'on','off'} 'on'; ...
%     'type'          'string'    {'coher','phasecoher','phasecoher2'}  'phasecoher'; ...
%     'itctype'       'string'    {'coher','phasecoher','phasecoher2'}  'phasecoher'; ...
%     'phsamp'        'string'    {'on','off'} 'off'; ...  % phsamp not completed - Toby 9.28.2006
%     'plotphaseonly' 'string'    {'on','off'} 'off'; ...
%     'plotphasesign' 'string'    {'on','off'} 'on'; ...
%     'plotphase'     'string'    {'on','off'} 'on'; ... % same as above for backward compatibility
%     'pcontour'      'string'    {'on','off'} 'off'; ... 
%     'outputformat'  'string'    {'old','new','plot' } 'plot'; ...
%     'itcmax'        'real'      []           []; ...
%     'erspmax'       'real'      []           []; ...
%     'lowmem'        'string'    {'on','off'} 'off'; ...
%     'verbose'       'string'    {'on','off'} 'on'; ...
%     'plottype'      'string'    {'image','curve'}   'image'; ...
%     'mcorrect'      'string'    {'fdr','none'}      'none'; ...
%     'plotmean'      'string'    {'on','off'} 'on'; ...
%     'plotmode'      'string'    {}           ''; ... % for metaplottopo
%     'highlightmode' 'string'    {'background','bottom'}     'background'; ...
%     'chaninfo'      'struct'    []           struct([]); ...
%     'erspmarglim'   'real'      []           []; ...
%     'itcavglim'     'real'      []           []; ...
%     'erplim'        'real'      []           []; ...
%     'speclim'       'real'      []           []; ...
%     'ntimesout'     'real'      []           []; ...
%     'scale'         'string'    { 'log','abs'} 'log'; ...
%     'timewarp'      'real'      []           []; ...
%     'precomputed'   'struct'    []           struct([]); ...
%     'timewarpms'    'real'      []           []; ...
%     'timewarpfr'    'real'      []           []; ...
%     'timewarpidx'   'real'      []           []; ...
%     'timewarpidx'   'real'      []           []; ...
%     'timeStretchMarks'  'real'  []           []; ...
%     'timeStretchRefs'   'real'  []           []; ...
%     'timeStretchPlot'   'real'  []           []; ...
%     'trialbase'     'string'    {'on','off','full'} 'off'; 
%     'caption'       'string'    []           ''; ...
%     'hzdir'         'string'    {'up','down','normal','reverse'}   HZDIR; ...
%     'ydir'          'string'    {'up','down','normal','reverse'}   YDIR; ...
%     'cycleinc'      'string'   {'linear','log'}        'linear'
%     }, 'newtimef', 'ignore');

g.scale = scale;
g.tlimits = tlimits;
g.frames  = frames;
g.srate   = Fs;
if isempty(g.cycles)
    g.cycles  = varwin;
end;
%g.padratio = padratio;
g.freqs = frange;
g.maxfreq = frange(2);
g.naccu = 200;
g.alpha = alpha;
g.mcorrect = fdr;
g.basenorm = bnorm; 

g.baseboot = 1;
% if ~isempty(g.nfreqs)
%     verboseprintf(g.verbose, 'Warning: ''nfreqs'' input overwrite ''padratio''\n');
% end;
g.baseline = 0;
g.trialbase = 'off';
g.powbase = NaN;
g.pboot = NaN;
g.rboot = NaN;
g.boottype = 'shuffle'; %{'shuffle','rand','randall'}    



if strcmpi(g.basenorm, 'on')
    verboseprintf(g.verbose, 'Baseline normalization is on (results will be shown as z-scores)\n');
end;

% Determining source of the call 
% --------------------------------------% 'guicall'= 1 if newtimef is called 
guicall = 0;

% test argument consistency
% --------------------------
if g.tlimits(2)-g.tlimits(1) < 30
    verboseprintf(g.verbose, 'newtimef(): WARNING: Specified time range is very small (< 30 ms)???\n');
    verboseprintf(g.verbose, '                     Epoch time limits should be in msec, not seconds!\n');
end

if (g.winsize > g.frames)
    error('Value of winsize must be smaller than epoch frames.');
end

if length(g.timesout) == 1 && g.timesout > 0
    if g.timesout > g.frames-g.winsize
        g.timesout = g.frames-g.winsize;
        disp(['Value of timesout must be <= frames-winsize, timeout adjusted to ' int2str(g.timesout) ]);
    end
end;

if (pow2(nextpow2(g.padratio)) ~= g.padratio)
    error('Value of padratio must be an integer power of two [1,2,4,8,16,...]');
end

if (g.maxfreq > Fs/2)
    verboseprintf(g.verbose, ['Warning: value of maxfreq reduced to Nyquist rate' ...
        ' (%3.2f)\n\n'], Fs/2);
    g.maxfreq = Fs/2;
end

if (round(g.naccu*g.alpha) < 2)
    verboseprintf(g.verbose, 'Value of alpha is outside its normal range [%g,0.5]\n',2/g.naccu);
    g.naccu = round(2/g.alpha);
    verboseprintf(g.verbose, '  Increasing the number of iterations to %d\n',g.naccu);
end

if ~isnan(g.alpha)
    if length(g.baseboot) == 2
        verboseprintf(g.verbose, 'Permutation analysis will use data from %3.2g to %3.2g ms.\n', ...
            g.baseboot(1),  g.baseboot(2))
    elseif g.baseboot > 0
        verboseprintf(g.verbose, 'Permutation analysis will use data in (pre-0) baseline subwindows only.\n')
    else
        verboseprintf(g.verbose, 'Permutation analysis will use data in all subwindows.\n')
    end
end

%%%%%%%%%%%%%%%%%%%%%%
% display text to user (computation perfomed only for display)
%%%%%%%%%%%%%%%%%%%%%%
verboseprintf(g.verbose, 'Computing Event-Related Spectral Perturbation (ERSP) and\n');
verboseprintf(g.verbose, '  of %d frames sampled at %g Hz.\n',g.frames,g.srate);
verboseprintf(g.verbose, 'Each trial contains samples from %1.0f ms before to\n',g.tlimits(1));
verboseprintf(g.verbose, '  %1.0f ms after the timelocking event.\n',g.tlimits(2));
if ~isnan(g.alpha)
    verboseprintf(g.verbose, 'Only significant values (permutation statistics p<%g) will be colored;\n',g.alpha)
    verboseprintf(g.verbose, '  non-significant values will be plotted in green\n');
end

if isempty(g.precomputed)
    % -----------------------------------------
    % detrend over epochs (trials) if requested
    % -----------------------------------------
%     if strcmpi(g.rmerp, 'on')
%         if ndims(data) == 2
%              data = data - mean(data,2)*ones(1, length(data(:))/g.frames);
%         else data = data - repmat(mean(data,3), [1 1 trials]);
%         end;
%     end;

    % ----------------------------------------------------
    % compute time frequency decompositions, power and ITC
    % ----------------------------------------------------
    if length(g.timesout) > 1,   tmioutopt = { 'timesout' , g.timesout };
    elseif ~isempty(g.ntimesout) tmioutopt = { 'ntimesout', g.ntimesout };
    else                         tmioutopt = { 'ntimesout', g.timesout };
    end;

    [alltfX freqs timesout R] = timefreq(data, g.srate, tmioutopt{:}, ...
        'winsize', g.winsize, 'tlimits', g.tlimits,  ...
        'itctype', g.type, 'wavelet', g.cycles, 'verbose', g.verbose, ...
        'padratio', g.padratio, 'freqs', g.freqs, 'freqscale', g.freqscale, ...
        'nfreqs', g.nfreqs, timefreqopts{:});
else
    alltfX   = g.precomputed.tfdata;
    timesout = g.precomputed.times;
    freqs    = g.precomputed.freqs;
    if strcmpi(g.precomputed.recompute, 'ersp')
        R = [];
    else
        switch g.itctype
            case 'coher',       R = alltfX ./ repmat(sqrt(sum(alltfX .* conj(alltfX),3) * size(alltfX,3)), [1 1 size(alltfX,3)]);
            case 'phasecoher2', R = alltfX ./ repmat(sum(sqrt(alltfX .* conj(alltfX)),3), [1 1 size(alltfX,3)]);
            case 'phasecoher',  R = alltfX ./ sqrt(alltfX .* conj(alltfX));
        end;
        P = []; mbase = []; return;
    end;
end;

if g.cycles(1) == 0
    alltfX = 2/0.375*alltfX/g.winsize; % TF and MC (12/11/2006): normalization, divide by g.winsize
    P  = alltfX.*conj(alltfX); % power    
    % TF and MC (12/14/2006): multiply by 2 account for negative frequencies,
    % and ounteract the reduction by a factor 0.375 that occurs as a result of 
    % cosine (Hann) tapering. Refer to Bug 446
    % Modified again 04/29/2011 due to comment in bug 1032
else 
    P  = alltfX.*conj(alltfX); % power for wavelets
end;

% ---------------
% baseline length
% ---------------
if size(g.baseline,2) == 2
    baseln = [];
    for index = 1:size(g.baseline,1)
        tmptime   = find(timesout >= g.baseline(index,1) & timesout <= g.baseline(index,2));
        baseln = union_bc(baseln, tmptime);
    end;
    if length(baseln)==0
        error( [ 'There are no sample points found in the default baseline.' 10 ...
                 'This may happen even though data time limits overlap with' 10 ...
                 'the baseline period (because of the time-freq. window width).' 10 ... 
                 'Either disable the baseline, change the baseline limits.' ] );
    end
else
    if ~isempty(find(timesout < g.baseline))
         baseln = find(timesout < g.baseline); % subtract means of pre-0 (centered) windows
    else baseln = 1:length(timesout); % use all times as baseline
    end
end;

if ~isnan(g.alpha) && length(baseln)==0
    verboseprintf(g.verbose, 'timef(): no window centers in baseline (times<%g) - shorten (max) window length.\n', g.baseline)
    return
end

% -----------------------------------------
% remove baseline on a trial by trial basis
% -----------------------------------------
if strcmpi(g.trialbase, 'on'), tmpbase = baseln;
else                           tmpbase = 1:size(P,2); % full baseline
end;
if ndims(P) == 4
    if ~strcmpi(g.trialbase, 'off') && isnan( g.powbase(1) )
        mbase = mean(P(:,:,tmpbase,:),3);
        if strcmpi(g.basenorm, 'on')
             mstd = std(P(:,:,tmpbase,:),[],3);
             P = bsxfun(@rdivide, bsxfun(@minus, P, mbase), mstd);
        else P = bsxfun(@rdivide, P, mbase);
        end;
    end;
else
    if ~strcmpi(g.trialbase, 'off') && isnan( g.powbase(1) )
        mbase = mean(P(:,tmpbase,:),2);
        if strcmpi(g.basenorm, 'on')
            mstd = std(P(:,tmpbase,:),[],2);
            P = (P-repmat(mbase,[1 size(P,2) 1]))./repmat(mstd,[1 size(P,2) 1]); % convert to log then back to normal
        else
            P = P./repmat(mbase,[1 size(P,2) 1]); 
            %P = 10 .^ (log10(P) - repmat(log10(mbase),[1 size(P,2) 1])); % same as above
        end;
    end;
end;

% -----------------------
% compute baseline values
% -----------------------
if isnan(g.powbase(1))

    verboseprintf(g.verbose, 'Computing the mean baseline spectrum\n');
    if ndims(P) == 4
        if ndims(P) > 3, Pori  = mean(P, 4); else Pori = P; end; 
        mbase = mean(Pori(:,:,baseln),3);
    else
        if ndims(P) > 2, Pori  = mean(P, 3); else Pori = P; end; 
        mbase = mean(Pori(:,baseln),2);
    end;
else
    verboseprintf(g.verbose, 'Using the input baseline spectrum\n');
    mbase    = g.powbase; 
    if strcmpi(g.scale, 'log'), mbase = 10.^(mbase/10); end; 
    if size(mbase,1) == 1 % if input was a row vector, flip to be a column
        mbase = mbase';
    end;
end
baselength = length(baseln);

% -------------------------
% remove baseline (average)
% -------------------------
% original ERSP baseline removal
if ~strcmpi(g.trialbase, 'on')
    if ~isnan( g.baseline(1) ) && any(~isnan( mbase(1) )) && strcmpi(g.basenorm, 'off')
        P = bsxfun(@rdivide, P, mbase); % use single trials
    % ERSP baseline normalized
    elseif ~isnan( g.baseline(1) ) && ~isnan( mbase(1) ) && strcmpi(g.basenorm, 'on')

        if ndims(Pori) == 3, 
             mstd = std(Pori(:,:,baseln),[],3);
        else mstd = std(Pori(:,baseln),[],2);
        end;
        P = bsxfun(@rdivide, bsxfun(@minus, P, mbase), mstd);
    end;
end;

% ---------
% bootstrap
% --------- % this ensures that if bootstrap limits provided that no
% 'alpha' won't prevent application of the provided limits
if ~isnan(g.alpha) | ~isempty(find(~isnan(g.pboot))) | ~isempty(find(~isnan(g.rboot)))% if bootstrap analysis requested . . .
    
    % ERSP bootstrap
    % --------------
    if ~isempty(find(~isnan(g.pboot))) % if ERSP bootstrap limits provided already
        Pboot = g.pboot(:);
    else
        if size(g.baseboot,2) == 1
            if g.baseboot == 0, baselntmp = [];
            elseif ~isnan(g.baseline(1))
                baselntmp = baseln;
            else baselntmp = find(timesout <= 0); % if it is empty use whole epoch
            end;
        else
            baselntmp = [];
            for index = 1:size(g.baseboot,1)
                tmptime   = find(timesout >= g.baseboot(index,1) & timesout <= g.baseboot(index,2));
                if isempty(tmptime),
                    fprintf('Warning: empty baseline interval [%3.2f %3.2f]\n', g.baseboot(index,1), g.baseboot(index,2));
                end;
                baselntmp = union_bc(baselntmp, tmptime);
            end;
        end;
        if prod(size(g.baseboot)) > 2
            fprintf('Permutation statistics will use data in multiple selected windows.\n');
        elseif size(g.baseboot,2) == 2
            fprintf('Permutation statistics will use data in range %3.2g-%3.2g ms.\n', g.baseboot(1),  g.baseboot(2));
        elseif g.baseboot
            fprintf('   %d permutation statistics windows in baseline (times<%g).\n', length(baselntmp), g.baseboot)
        end;
        
        % power significance
        % ------------------
        if strcmpi(g.boottype, 'shuffle')
            formula = 'mean(arg1,3);';
            [ Pboot Pboottrialstmp Pboottrials] = bootstat(P, formula, 'boottype', 'shuffle', ...
                'label', 'ERSP', 'bootside', 'both', 'naccu', g.naccu, ...
                'basevect', baselntmp, 'alpha', g.alpha, 'dimaccu', 2 );
            clear Pboottrialstmp;
        else
            center = 0;
            if strcmpi(g.basenorm, 'off'), center = 1; end;
            
            % bootstrap signs
            Pboottmp    = P;
            Pboottrials = zeros([ size(P,1) size(P,2) g.naccu ]);
            for index = 1:g.naccu
                Pboottmp = (Pboottmp-center).*(ceil(rand(size(Pboottmp))*2-1)*2-1)+center;
                Pboottrials(:,:,index) = mean(Pboottmp,3);
            end;
            Pboot = [];
        end;
        if size(Pboot,2) == 1, Pboot = Pboot'; end;
    end;       
else
    Pboot = []; Rboot = [];
end

% average the power
% -----------------
PA = P;
if ndims(P) == 4,     P = mean(P, 4);
elseif ndims(P) == 3, P = mean(P, 3);
end;

% correction for multiple comparisons
% -----------------------------------
maskersp = [];
maskitc  = []; 
if ~isnan(g.alpha)
    if isempty(find(~isnan(g.pboot))) % if ERSP lims not provided
        if ndims(Pboottrials) < 3, Pboottrials = Pboottrials'; end;
        exactp_ersp = compute_pvals(P, Pboottrials);
        if strcmpi(g.mcorrect, 'fdr')
            alphafdr = fdr(exactp_ersp, g.alpha);
            if alphafdr ~= 0
                fprintf('ERSP correction for multiple comparisons using FDR, alpha_fdr = %3.6f\n', alphafdr);
            else fprintf('ERSP correction for multiple comparisons using FDR, nothing significant\n', alphafdr);
            end;
            maskersp = exactp_ersp <= alphafdr;
        else
            maskersp = exactp_ersp <= g.alpha;
        end;
    end;    
end;

% convert to log if necessary
% ---------------------------
if strcmpi(g.scale, 'log')
    if ~isnan( g.baseline(1) ) && ~isnan( mbase(1) ) && strcmpi(g.trialbase, 'off'), mbase = log10(mbase)*10; end;
    P = 10 * log10(P);
    if ~isempty(Pboot)
        Pboot = 10 * log10(Pboot);
    end;
end;
if isempty(Pboot) && exist('maskersp')
    Pboot = maskersp;
end;

% % --------
% % plotting
% % --------
% if strcmpi(g.plotersp, 'on') || strcmpi(g.plotitc, 'on')
%     if ndims(P) == 3
%         P = squeeze(P(2,:,:,:));
%         R = squeeze(R(2,:,:,:));
%         mbase = squeeze(mbase(2,:));
%         ERP = mean(squeeze(data(1,:,:)),2);
%     else      
%         ERP = mean(data,2);
%     end;
%     if strcmpi(g.plottype, 'image')
%         plottimef(P, R, Pboot, Rboot, ERP, freqs, timesout, mbase, maskersp, maskitc, g);
%     else
%         plotallcurves(P, R, Pboot, Rboot, ERP, freqs, timesout, mbase, g);
%     end;
% end;

mbase = mbase';

return;

