function [P,R,mbase,timesout,freqs,Pboot,Rboot,alltfX,g] = m_newtimef_2_conditions(data, frames, tlimits, Fs, varwin, varargin);

% Note: Above, PA is output of 'phsamp','on'

% For future 'timewarp' keyword help: 'timewarp' 3rd element {colors} contains a
%               list of Matlab linestyles to use for vertical lines marking the occurence
%               of the time warped events. If '', no line will be drawn for this event
%               column. If fewer colors than event columns, cycles through the given color
%               labels.  Note: Not compatible with 'vert' (below).

%varwin,winsize,g.timesout,g.padratio,g.maxfreq,g.topovec,g.elocs,g.alpha,g.marktimes,g.powbase,g.pboot,g.rboot)

% ITC:   Normally, R = |Sum(Pxy)| / (Sum(|Pxx|)*Sum(|Pyy|)) is coherence.
%        But here, we consider    Phase(Pyy) = 0 and |Pyy| = 1 -> Pxy = Pxx
%        Giving, R = |Sum(Pxx)|/Sum(|Pxx|), the inter-trial coherence (ITC)
%        Also called 'phase-locking factor' by Tallon-Baudry et al. (1996)

% if nargin < 1
%     help newtimef;
%     return;
% end;

% Read system (or directory) constants and preferences:
% ------------------------------------------------------
icadefs % read local EEGLAB constants: HZDIR, YDIR, DEFAULT_SRATE, DEFAULT_TIMLIM

if ~exist('HZDIR'), HZDIR = 'up'; end; % ascending freqs
if ~exist('YDIR'), YDIR = 'up'; end;   % positive up

if YDIR == 1, YDIR = 'up'; end;        % convert from [-1|1] as set in icadefs.m  
if YDIR == -1, YDIR = 'down'; end;     % and read by other plotting functions

if ~exist('DEFAULT_SRATE'), DEFAULT_SRATE = 250; end;            % 250 Hz
if ~exist('DEFAULT_TIMLIM'), DEFAULT_TIMLIM = [-1000 2000]; end; % [-1 2] s epochs

% Constants set here:
% ------------------
ERSP_CAXIS_LIMIT = 0;           % 0 -> use data limits; else positive value
% giving symmetric +/- caxis limits.
ITC_CAXIS_LIMIT  = 0;           % 0 -> use data limits; else positive value
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
DEFAULT_MAXFREQ = 50;		% Maximum frequency to display (Hz)
DEFAULT_TITLE	= '';		% Figure title (no default)
DEFAULT_ELOC    = 'chan.locs';	% Channel location file
DEFAULT_ALPHA   = NaN;		% Percentile of bins to keep
DEFAULT_MARKTIME= NaN;

% Font sizes:
AXES_FONT       = 10;           % axes text FontSize
TITLE_FONT      =  10;

if (nargin < 2)
    frames = floor((DEFAULT_TIMLIN(2)-DEFAULT_TIMLIM(1))/DEFAULT_SRATE);
elseif (~isnumeric(frames) | length(frames)~=1 | frames~=round(frames))
    error('Value of frames must be an integer.');
elseif (frames <= 0)
    error('Value of frames must be positive.');
end;

DEFAULT_WINSIZE = max(pow2(nextpow2(frames)-3),4);
DEFAULT_PAD = max(pow2(nextpow2(DEFAULT_WINSIZE)),4);

if (nargin < 1)
    help newtimef
    return
end

if isstr(data) && strcmp(data,'details')
    more on
    help timefdetails
    more off
    return
end
if ~iscell(data)
    data = reshape_data(data, frames);
    trials = size(data,ndims(data));
else
    if ndims(data) == 3 && size(data,1) == 1
        error('Cannot process multiple channel component in compare mode');
    end;
    [data{1}, frames] = reshape_data(data{1}, frames);
    [data{2}, frames] = reshape_data(data{2}, frames);
    trials = size(data{1},2);
end;

if (nargin < 3)
    tlimits = DEFAULT_TIMLIM;
elseif (~isnumeric(tlimits) | sum(size(tlimits))~=3)
    error('Value of tlimits must be a vector containing two numbers.');
elseif (tlimits(1) >= tlimits(2))
    error('tlimits interval must be ascending.');
end

if (nargin < 4)
    Fs = DEFAULT_SRATE;
elseif (~isnumeric(Fs) | length(Fs)~=1)
    error('Value of srate must be a number.');
elseif (Fs <= 0)
    error('Value of srate must be positive.');
end

if (nargin < 5)
    varwin = DEFAULT_VARWIN;
elseif ~isnumeric(varwin) && strcmpi(varwin, 'cycles')
    varwin = varargin{1};
    varargin(1) = [];
elseif (varwin < 0)
    error('Value of cycles must be zero or positive.');
end

% build a structure for keyword arguments
% --------------------------------------
if ~isempty(varargin)
    [tmp indices] = unique_bc(varargin(1:2:end));
    varargin = varargin(sort(union(indices*2-1, indices*2))); % these 2 lines remove duplicate arguments
    try, g = struct(varargin{:});
    catch, error('Argument error in the {''param'', value} sequence'); end;
end
%}
[ g timefreqopts ] = finputcheck(varargin, ...
    {'boottype'      'string'    {'shuffle','rand','randall'}    'shuffle'; ...
    'condboot'      'string'    {'abs','angle','complex'}       'abs'; ...
    'title'         { 'string','cell' }   { [] [] }         DEFAULT_TITLE; ...
    'title2'        'string'    []          DEFAULT_TITLE; ...
    'winsize'       'integer'      [0 Inf]  DEFAULT_WINSIZE; ...
    'pad'           'real'      []          DEFAULT_PAD; ...
    'timesout'      'integer'   []          DEFAULT_NWIN; ...
    'padratio'      'integer'   [0 Inf]     DEFAULT_OVERSMP; ...
    'topovec'       'real'      []          []; ...
    'elocs'         {'string','struct'} []  DEFAULT_ELOC; ...
    'alpha'         'real'      [0 0.5]     DEFAULT_ALPHA; ...
    'marktimes'     'real'      []          DEFAULT_MARKTIME; ...
    'powbase'       'real'      []          NaN; ...
    'pboot'         'real'      []          NaN; ...
    'rboot'         'real'      []          NaN; ...
    'plotersp'      'string'    {'on','off'} 'on'; ...
    'plotamp'       'string'    {'on','off'} 'on'; ...
    'plotitc'       'string'    {'on','off'} 'on'; ...
    'detrend'       'string'    {'on','off'} 'off'; ...
    'rmerp'         'string'    {'on','off'} 'off'; ...
    'basenorm'      'string'    {'on','off'} 'off'; ...
    'commonbase'    'string'    {'on','off'} 'on'; ...
    'baseline'      'real'      []           0; ...
    'baseboot'      'real'      []           1; ...
    'linewidth'     'integer'   [1 2]        2; ...
    'naccu'         'integer'   [1 Inf]      200; ...
    'mtaper'        'real'      []           []; ...
    'maxfreq'       'real'      [0 Inf]      DEFAULT_MAXFREQ; ...
    'freqs'         'real'      [0 Inf]      [0 DEFAULT_MAXFREQ]; ...
    'cycles'        'integer'   []           []; ...
    'nfreqs'        'integer'   []           []; ...
    'freqscale'     'string'    []           'linear'; ...
    'vert'          'real'      []           [];  ...
    'newfig'        'string'    {'on','off'} 'on'; ...
    'type'          'string'    {'coher','phasecoher','phasecoher2'}  'phasecoher'; ...
    'itctype'       'string'    {'coher','phasecoher','phasecoher2'}  'phasecoher'; ...
    'phsamp'        'string'    {'on','off'} 'off'; ...  % phsamp not completed - Toby 9.28.2006
    'plotphaseonly' 'string'    {'on','off'} 'off'; ...
    'plotphasesign' 'string'    {'on','off'} 'on'; ...
    'plotphase'     'string'    {'on','off'} 'on'; ... % same as above for backward compatibility
    'pcontour'      'string'    {'on','off'} 'off'; ... 
    'outputformat'  'string'    {'old','new','plot' } 'plot'; ...
    'itcmax'        'real'      []           []; ...
    'erspmax'       'real'      []           []; ...
    'lowmem'        'string'    {'on','off'} 'off'; ...
    'verbose'       'string'    {'on','off'} 'on'; ...
    'plottype'      'string'    {'image','curve'}   'image'; ...
    'mcorrect'      'string'    {'fdr','none'}      'none'; ...
    'plotmean'      'string'    {'on','off'} 'on'; ...
    'plotmode'      'string'    {}           ''; ... % for metaplottopo
    'highlightmode' 'string'    {'background','bottom'}     'background'; ...
    'chaninfo'      'struct'    []           struct([]); ...
    'erspmarglim'   'real'      []           []; ...
    'itcavglim'     'real'      []           []; ...
    'erplim'        'real'      []           []; ...
    'speclim'       'real'      []           []; ...
    'ntimesout'     'real'      []           []; ...
    'scale'         'string'    { 'log','abs'} 'log'; ...
    'timewarp'      'real'      []           []; ...
    'precomputed'   'struct'    []           struct([]); ...
    'timewarpms'    'real'      []           []; ...
    'timewarpfr'    'real'      []           []; ...
    'timewarpidx'   'real'      []           []; ...
    'timewarpidx'   'real'      []           []; ...
    'timeStretchMarks'  'real'  []           []; ...
    'timeStretchRefs'   'real'  []           []; ...
    'timeStretchPlot'   'real'  []           []; ...
    'trialbase'     'string'    {'on','off','full'} 'off'; 
    'caption'       'string'    []           ''; ...
    'hzdir'         'string'    {'up','down','normal','reverse'}   HZDIR; ...
    'ydir'          'string'    {'up','down','normal','reverse'}   YDIR; ...
    'cycleinc'      'string'   {'linear','log'}        'linear'
    }, 'newtimef', 'ignore');
if isstr(g), error(g); end;
if strcmpi(g.plotamp, 'off'), g.plotersp = 'off'; end;    
if strcmpi(g.basenorm, 'on'), g.scale = 'abs'; end;
if ~strcmpi(g.itctype , 'phasecoher'), g.type = g.itctype; end;

g.tlimits = tlimits;
g.frames  = frames;
g.srate   = Fs;
if isempty(g.cycles)
    g.cycles  = varwin;
end;
g.AXES_FONT        = AXES_FONT;      % axes text FontSize
g.TITLE_FONT       = TITLE_FONT;
g.ERSP_CAXIS_LIMIT = ERSP_CAXIS_LIMIT;
g.ITC_CAXIS_LIMIT  = ITC_CAXIS_LIMIT;
if ~strcmpi(g.plotphase, 'on'), g.plotphasesign = g.plotphase; end;

% unpack 'timewarp' (and undocumented 'timewarpfr') arguments
%------------------------------------------------------------
if isfield(g,'timewarpfr')
    if iscell(g.timewarpfr) && length(g.timewarpfr) > 3
        error('undocumented ''timewarpfr'' cell array may have at most 3 elements');
    end
end

if ~isempty(g.nfreqs)
    verboseprintf(g.verbose, 'Warning: ''nfreqs'' input overwrite ''padratio''\n');
end;
if strcmpi(g.basenorm, 'on')
    verboseprintf(g.verbose, 'Baseline normalization is on (results will be shown as z-scores)\n');
end;

if isfield(g,'timewarp') && ~isempty(g.timewarp)
    if ndims(data) == 3
        error('Cannot perform time warping on 3-D data input');
    end;
    if ~isempty(g.timewarp) % convert timewarp ms to timewarpfr frames -sm
        fprintf('\n')
        if iscell(g.timewarp)
           error('timewarp argument must be a (total_trials,epoch_events) matrix');
        end
        evntms = g.timewarp;
        warpfr = round((evntms - g.tlimits(1))/1000*g.srate)+1;
        g.timewarpfr{1} = warpfr';

        if isfield(g,'timewarpms')
           refms = g.timewarpms;
           reffr = round((refms - g.tlimits(1))/1000*g.srate)+1;
           g.timewarpfr{2} = reffr';
        end
        if isfield(g,'timewarpidx')
           g.timewarpfr{3} = g.timewarpidx;
        end
    end

    % convert again to timeStretch parameters
    % ---------------------------------------
    if ~isempty(g.timewarpfr)
        g.timeStretchMarks = g.timewarpfr{1};
        if length(g.timewarpfr) > 1
            g.timeStretchRefs = g.timewarpfr{2};
        end

        if length(g.timewarpfr) > 2
          if isempty(g.timewarpfr{3})
            stretchevents = size(g.timeStretchMarks,1);
            g.timeStretchPlot = [1:stretchevents]; % default to plotting all lines
          else
            g.timeStretchPlot = g.timewarpfr{3};
          end
        end

        if max(max(g.timeStretchMarks)) > frames-2 | min(min(g.timeStretchMarks)) < 3
            error('Time warping events must be inside the epochs.');
        end
        if ~isempty(g.timeStretchRefs)
            if max(g.timeStretchRefs) > frames-2 | min(g.timeStretchRefs) < 3
                error('Time warping reference latencies must be within the epochs.');
            end
        end
    end
end

% Determining source of the call 
% --------------------------------------% 'guicall'= 1 if newtimef is called 
callerstr = dbstack(1);                 % from EEGLAB GUI, otherwise 'guicall'= 0
if isempty(callerstr)                   % 7/3/2014, Ramon
    guicall = 0;
elseif strcmp(callerstr(end).name,'pop_newtimef')     
    guicall = 1;
else
    guicall = 0;
end

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
if g.maxfreq ~= DEFAULT_MAXFREQ, g.freqs(2) = g.maxfreq; end;

if isempty(g.topovec)
    g.topovec = [];
    if isempty(g.elocs)
        error('Channel location file must be specified.');
    end;
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

if ~isempty(g.timeStretchMarks) % timeStretch code by Jean Hauser
    if isempty(g.timeStretchRefs)
        verboseprintf(g.verbose, ['Using median event latencies as reference event times for time warping.\n']);
        g.timeStretchRefs = median(g.timeStretchMarks,2); 
                                          % Note: Uses (grand) median latencies for two conditions
    else
        verboseprintf(g.verbose, ['Using supplied latencies as reference event times for time warping.\n']);
    end
    if isempty(g.timeStretchPlot)
        verboseprintf(g.verbose, 'Will not overplot the reference event times on the ERSP.\n');
    elseif length(g.timeStretchPlot) > 0
        g.vert = ((g.timeStretchRefs(g.timeStretchPlot)-1) ...
            /g.srate+g.tlimits(1)/1000)*1000;
        fprintf('Plotting timewarp markers at ')
           for li = 1:length(g.vert), fprintf('%d ',g.vert(li)); end
        fprintf(' ms.\n')
    end
end 

if min(g.vert) < g.tlimits(1) | max(g.vert) > g.tlimits(2)
    error('vertical line (''vert'') latency outside of epoch boundaries');
end

if strcmp(g.hzdir,'up')| strcmp(g.hzdir,'normal')
    g.hzdir = 'normal'; % convert to Matlab graphics constants
elseif strcmp(g.hzdir,'down') | strcmp(g.hzdir,'reverse')| g.hzdir==-1
    g.hzdir = 'reverse';
else
    error('unknown ''hzdir'' argument'); 
end

if strcmp(g.ydir,'up')| strcmp(g.ydir,'normal')
    g.ydir = 'normal'; % convert to Matlab graphics constants
elseif strcmp(g.ydir,'down') | strcmp(g.ydir,'reverse')
    g.ydir = 'reverse';
else
    error('unknown ''ydir'' argument'); 
end

% -----------------
% ERSP scaling unit
% -----------------
if strcmpi(g.scale, 'log')
    if strcmpi(g.basenorm, 'on')
        g.unitpower = '10*log(std.)'; % impossible
    elseif isnan(g.baseline)
        g.unitpower = '10*log10(\muV^{2}/Hz)';
    else
        g.unitpower = 'dB';
    end;
else
    if strcmpi(g.basenorm, 'on')
        g.unitpower = 'std.';
    elseif isnan(g.baseline)
        g.unitpower = '\muV^{2}/Hz';
    else
        g.unitpower = '% of baseline';
    end;
end;

% Multitaper - used in timef
% --------------------------
if ~isempty(g.mtaper) % multitaper, inspired from a Bijan Pesaran matlab function
    if length(g.mtaper) < 3
        %error('mtaper arguement must be [N W] or [N W K]');

        if g.mtaper(1) * g.mtaper(2) < 1
            error('mtaper 2 first arguments'' product must be larger than 1');
        end;
        if length(g.mtaper) == 2
            g.mtaper(3) = floor( 2*g.mtaper(2)*g.mtaper(1) - 1);
        end
        if length(g.mtaper) == 3
            if g.mtaper(3) > 2 * g.mtaper(1) * g.mtaper(2) -1
                error('mtaper number too high (maximum (2*N*W-1))');
            end;
        end
        disp(['Using ' num2str(g.mtaper(3)) ' tapers.']);
        NW = g.mtaper(1)*g.mtaper(2);   % product NW
        N  = g.mtaper(1)*g.srate;
        [e,v] = dpss(N, NW, 'calc');
        e=e(:,1:g.mtaper(3));
        g.alltapers = e;
    else
        g.alltapers = g.mtaper;
        disp('mtaper argument not [N W] or [N W K]; considering raw taper matrix');
    end;
    g.winsize = size(g.alltapers, 1);
    g.pad = max(pow2(nextpow2(g.winsize)),256); % pad*nextpow
    nfk = floor([0 g.maxfreq]./g.srate.*g.pad);
    g.padratio = 2*nfk(2)/g.winsize;

    %compute number of frequencies
    %nf = max(256, g.pad*2^nextpow2(g.winsize+1));
    %nfk = floor([0 g.maxfreq]./g.srate.*nf);

    %freqs = linspace( 0, g.maxfreq, diff(nfk)); % this also works in the case of a FFT
end

g.plotersp = 'off';
hdl = [];
%%%%%%%%%%%%%%%%%%%%%%%
% compare 2 conditions 
%%%%%%%%%%%%%%%%%%%%%%%
if iscell(data)
    if ~guicall && (strcmp(g.basenorm, 'on') || strcmp(g.trialbase, 'on'))  % ------------------------------------- Temporary fix for error when using
        error('EEGLAB error: basenorm and/or trialbase options cannot be used when processing 2 conditions');     % basenorm or trialbase with two conditions
    end;
    Pboot = [];
    Rboot = [];
    if ~strcmpi(g.mcorrect, 'none')
        error('Correction for multiple comparison not implemented for comparing conditions');
    end;
    
    vararginori = varargin;
    if length(data) ~= 2
        error('newtimef: to compare two conditions, data must be a length-2 cell array');
    end;
    
    % deal with titles
    % ----------------
    for index = 1:2:length(vararginori)
        if index<=length(vararginori) % needed if elements are deleted
            
            %  if      strcmp(vararginori{index}, 'title') | ... % Added by Jean Hauser
            %          strcmp(vararginori{index}, 'title2') | ...
            if strcmp(vararginori{index}, 'timeStretchMarks') | ...
                    strcmp(vararginori{index}, 'timeStretchRefs') | ...
                    strcmp(vararginori{index}, 'timeStretchPlots')
                vararginori(index:index+1) = [];
            end;
        end;
    end;
    if iscell(g.title) && length(g.title) >= 2 % Changed that part because providing titles
        % as cells caused the function to crash (why?)
        % at line 704 (g.tlimits = tlimits) -Jean
        if length(g.title) == 2,
            g.title{3} = [ g.title{1} ' - '  g.title{2} ];
        end;
    else
        disp('Warning: title must be a cell array');
        g.title = { 'Condition 1' 'Condition 2' 'Condition 1 minus Condition 2' };
    end;
    
    verboseprintf(g.verbose, '\nRunning newtimef() on Condition 1 **********************\n\n');
    
    verboseprintf(g.verbose, 'Note: If an out-of-memory error occurs, try reducing the\n');
    verboseprintf(g.verbose, '      the number of time points or number of frequencies\n');
    verboseprintf(g.verbose, '(''coher'' options take 3 times the memory of other options)\n\n');
    
    cond_1_epochs = size(data{1},2);
    
    if ~isempty(g.timeStretchMarks)
        [P1,R1,mbase1,timesout,freqs,Pboot1,Rboot1,alltfX1] = ...
            m_newtimef_2_conditions( data{1}, frames, tlimits, Fs, g.cycles, 'plotitc', 'off', ...
            'plotersp', 'off', vararginori{:}, 'lowmem', 'off', ...
            'timeStretchMarks', g.timeStretchMarks(:,1:cond_1_epochs), ...
            'timeStretchRefs', g.timeStretchRefs);
    else
        [P1,R1,mbase1,timesout,freqs,Pboot1,Rboot1,alltfX1] = ...
            m_newtimef_2_conditions( data{1}, frames, tlimits, Fs, g.cycles, 'plotitc', 'off', ...
            'plotersp', 'off', vararginori{:}, 'lowmem', 'off');
    end
    
    verboseprintf(g.verbose,'\nRunning m_newtimef() on Condition 2 **********************\n\n');
    
    [P2,R2,mbase2,timesout,freqs,Pboot2,Rboot2,alltfX2] = ...
        m_newtimef_2_conditions( data{2}, frames, tlimits, Fs, g.cycles, 'plotitc', 'off', ...
        'plotersp', 'off', vararginori{:}, 'lowmem', 'off', ...
        'timeStretchMarks', g.timeStretchMarks(:,cond_1_epochs+1:end), ...
        'timeStretchRefs', g.timeStretchRefs);
    
    verboseprintf(g.verbose,'\nComputing difference **********************\n\n');
    
    % recompute power baselines
    % -------------------------
    if ~isnan( g.baseline(1) ) && ~isnan( mbase1(1) ) && isnan(g.powbase(1)) && strcmpi(g.commonbase, 'on')
        disp('Recomputing baseline power: using the grand mean of both conditions ...');
        mbase = (mbase1 + mbase2)/2;
        P1 = P1 + repmat(mbase1(1:size(P1,1))',[1 size(P1,2)]);
        P2 = P2 + repmat(mbase2(1:size(P1,1))',[1 size(P1,2)]);
        P1 = P1 - repmat(mbase (1:size(P1,1))',[1 size(P1,2)]);
        P2 = P2 - repmat(mbase (1:size(P1,1))',[1 size(P1,2)]);
        if ~isnan(g.alpha)
            Pboot1 = Pboot1 + repmat(mbase1(1:size(Pboot1,1))',[1 size(Pboot1,2) size(Pboot1,3)]);
            Pboot2 = Pboot2 + repmat(mbase2(1:size(Pboot1,1))',[1 size(Pboot1,2) size(Pboot1,3)]);
            Pboot1 = Pboot1 - repmat(mbase (1:size(Pboot1,1))',[1 size(Pboot1,2) size(Pboot1,3)]);
            Pboot2 = Pboot2 - repmat(mbase (1:size(Pboot1,1))',[1 size(Pboot1,2) size(Pboot1,3)]);
        end;
        verboseprintf(g.verbose, '\nSubtracting the common power baseline ...\n');
        meanmbase = mbase;
        mbase = { mbase mbase };
    elseif strcmpi(g.commonbase, 'on')
        mbase = { NaN NaN };
        meanmbase = mbase{1}; %Ramon :for bug 1657 
    else
        meanmbase = (mbase1 + mbase2)/2;
        mbase = { mbase1 mbase2 };
    end;
    
    g.plotersp = 'on';
    
    % plotting
    % --------
    
    if strcmpi(g.plotersp, 'on') | strcmpi(g.plotitc, 'on')
        figure;
        g.titleall = g.title;
        %if strcmpi(g.newfig, 'on'), figure; end; % declare a new figure
        
        % using same color scale
        % ----------------------
        if ~isfield(g, 'erspmax')
            g.erspmax = max( max(max(abs(Pboot1))), max(max(abs(Pboot2))) );
        end;
        if ~isfield(g, 'itcmax')
            g.itcmax  = max( max(max(abs(Rboot1))), max(max(abs(Rboot2))) );
        end;
        
        subplot(1,3,1); % plot Condition 1
        g.title = g.titleall{1};        
        g = plottimef_for_2_conditions(P1, R1, Pboot1, Rboot1, freqs, timesout, mbase{1}, [], [], g);
        %g = plottimef_for_2_conditions(P1, R1, Pboot1, Rboot1, mean(data{1},2), freqs, timesout, mbase{1}, [], [], g);
        g.itcavglim = [];
        
        subplot(1,3,2); % plot Condition 2
        g.title = g.titleall{2};        
        g.topovec = [];        
        %plottimef_for_2_conditions(P2, R2, Pboot2, Rboot2, mean(data{2},2), freqs, timesout, mbase{2}, [], [], g);
        plottimef_for_2_conditions(P2, R2, Pboot2, Rboot2,  freqs, timesout, mbase{2}, [], [], g);
        
        subplot(1,3,3); % plot Condition 1 - Condition 2
        g.title =  g.titleall{3};
    end;
    
    if isnan(g.alpha)
        switch(g.condboot)
            case 'abs',  Rdiff = abs(R1)-abs(R2);
            case 'angle',  Rdiff = angle(R1)-angle(R2);
            case 'complex',  Rdiff = R1-R2;
        end;
        if strcmpi(g.plotersp, 'on') | strcmpi(g.plotitc, 'on')
            %g.erspmax = []; g.itcmax  = []; % auto scale inserted for diff
            %plottimef_for_2_conditions(P1-P2, Rdiff, [], [], mean(data{1},2)-mean(data{2},2), freqs, timesout, meanmbase, [], [], g);
            plottimef_for_2_conditions(P1-P2, Rdiff, [], [], freqs, timesout, meanmbase, [], [], g);
        end;
    else
        % preprocess data and run compstat() function
        % -------------------------------------------
        alltfX1power = alltfX1.*conj(alltfX1);
        alltfX2power = alltfX2.*conj(alltfX2);
        
        if ~isnan(mbase{1}(1))
            mbase1 = 10.^(mbase{1}(1:size(alltfX1,1))'/20);
            mbase2 = 10.^(mbase{2}(1:size(alltfX1,1))'/20);
            alltfX1 = alltfX1./repmat(mbase1/2,[1 size(alltfX1,2) size(alltfX1,3)]);
            alltfX2 = alltfX2./repmat(mbase2/2,[1 size(alltfX2,2) size(alltfX2,3)]);
            alltfX1power = alltfX1power./repmat(mbase1,[1 size(alltfX1power,2) size(alltfX1power,3)]);
            alltfX2power = alltfX2power./repmat(mbase2,[1 size(alltfX2power,2) size(alltfX2power,3)]);
        end;
        
        %formula = {'log10(mean(arg1,3))'};              % toby 10.02.2006
        %formula = {'log10(mean(arg1(:,:,data),3))'};
        
        formula = {'log10(mean(arg1(:,:,X),3))'};
        switch g.type
            case 'coher', % take the square of alltfx and alltfy first to speed up
                formula = { formula{1} ['sum(arg2(:,:,data),3)./sqrt(sum(arg1(:,:,data),3)*length(data) )'] };
                if strcmpi(g.lowmem, 'on')
                    for ind = 1:2:size(alltfX1power,1)
                        if ind == size(alltfX1,1), indarr = ind; else indarr = [ind:ind+1]; end;
                        [resdifftmp resimagestmp res1tmp res2tmp] = ...
                            condstat(formula, g.naccu, g.alpha, {'both' 'upper'}, { '' g.condboot}, ...
                            { alltfX1power(indarr,:,:) alltfX2power(indarr,:,:) }, {alltfX1(indarr,:,:) alltfX2(indarr,:,:)});
                        resdiff{1}(indarr,:)     = resdifftmp{1};   resdiff{2}(indarr,:)     = resdifftmp{2};
                        resimages{1}(indarr,:,:) = resimagestmp{1}; resimages{2}(indarr,:,:) = resimagestmp{2};
                        res1{1}(indarr,:)        = res1tmp{1};      res1{2}(indarr,:)        = res1tmp{2};
                        res2{1}(indarr,:)        = res2tmp{1};      res2{2}(indarr,:)        = res2tmp{2};
                    end;
                else
                    alltfXpower = { alltfX1power alltfX2power };
                    alltfX      = { alltfX1 alltfX2 };
                    alltfXabs   = { alltfX1abs alltfX2abs };
                    [resdiff resimages res1 res2] = condstat(formula, g.naccu, g.alpha, {'both' 'upper'}, { '' g.condboot}, alltfXpower, alltfX, alltfXabs);
                end;
            case 'phasecoher2', % normalize first to speed up
                
                %formula = { formula{1} ['sum(arg2(:,:,data),3)./sum(arg3(:,:,data),3)'] };
                % toby 10/3/2006
                
                formula = { formula{1} ['sum(arg2(:,:,X),3)./sum(arg3(:,:,X),3)'] };
                alltfX1abs = sqrt(alltfX1power); % these 2 lines can be suppressed
                alltfX2abs = sqrt(alltfX2power); % by inserting sqrt(arg1(:,:,data)) instead of arg3(:,:,data))
                if strcmpi(g.lowmem, 'on')
                    for ind = 1:2:size(alltfX1abs,1)
                        if ind == size(alltfX1,1), indarr = ind; else indarr = [ind:ind+1]; end;
                        [resdifftmp resimagestmp res1tmp res2tmp] = ...
                            condstat(formula, g.naccu, g.alpha, {'both' 'upper'}, { '' g.condboot}, ...
                            { alltfX1power(indarr,:,:) alltfX2power(indarr,:,:) }, {alltfX1(indarr,:,:) ...
                            alltfX2(indarr,:,:)}, { alltfX1abs(indarr,:,:) alltfX2abs(indarr,:,:) });
                        resdiff{1}(indarr,:)     = resdifftmp{1};   resdiff{2}(indarr,:)     = resdifftmp{2};
                        resimages{1}(indarr,:,:) = resimagestmp{1}; resimages{2}(indarr,:,:) = resimagestmp{2};
                        res1{1}(indarr,:)        = res1tmp{1};      res1{2}(indarr,:)        = res1tmp{2};
                        res2{1}(indarr,:)        = res2tmp{1};      res2{2}(indarr,:)        = res2tmp{2};
                    end;
                else
                    alltfXpower = { alltfX1power alltfX2power };
                    alltfX      = { alltfX1 alltfX2 };
                    alltfXabs   = { alltfX1abs alltfX2abs };
                    [resdiff resimages res1 res2] = condstat(formula, g.naccu, g.alpha, {'both' 'upper'}, { '' g.condboot}, alltfXpower, alltfX, alltfXabs);
                end;
            case 'phasecoher',
                
                %formula = { formula{1} ['mean(arg2,3)'] };              % toby 10.02.2006
                %formula = { formula{1} ['mean(arg2(:,:,data),3)'] };
                
                formula = { formula{1} ['mean(arg2(:,:,X),3)'] };
                if strcmpi(g.lowmem, 'on')
                    for ind = 1:2:size(alltfX1,1)
                        if ind == size(alltfX1,1), indarr = ind; else indarr = [ind:ind+1]; end;
                        alltfX1norm = alltfX1(indarr,:,:)./sqrt(alltfX1(indarr,:,:).*conj(alltfX1(indarr,:,:)));
                        alltfX2norm = alltfX2(indarr,:,:)./sqrt(alltfX2(indarr,:,:).*conj(alltfX2(indarr,:,:)));
                        alltfXpower = { alltfX1power(indarr,:,:) alltfX2power(indarr,:,:) };
                        alltfXnorm  = { alltfX1norm alltfX2norm };
                        [resdifftmp resimagestmp res1tmp res2tmp] = ...
                            condstat(formula, g.naccu, g.alpha, {'both' 'both'}, { '' g.condboot}, ...
                            alltfXpower, alltfXnorm);
                        resdiff{1}(indarr,:)     = resdifftmp{1};   resdiff{2}(indarr,:)     = resdifftmp{2};
                        resimages{1}(indarr,:,:) = resimagestmp{1}; resimages{2}(indarr,:,:) = resimagestmp{2};
                        res1{1}(indarr,:)        = res1tmp{1};      res1{2}(indarr,:)        = res1tmp{2};
                        res2{1}(indarr,:)        = res2tmp{1};      res2{2}(indarr,:)        = res2tmp{2};
                    end;
                else
                    alltfX1norm = alltfX1./sqrt(alltfX1.*conj(alltfX1));
                    alltfX2norm = alltfX2./sqrt(alltfX2.*conj(alltfX2)); % maybe have to suppress preprocessing -> lot of memory
                    alltfXpower = { alltfX1power alltfX2power };
                    alltfXnorm  = { alltfX1norm alltfX2norm };
                    [resdiff resimages res1 res2] = condstat(formula, g.naccu, g.alpha, {'both' 'both'}, { '' g.condboot}, ...
                        alltfXpower, alltfXnorm);
                end;
        end;
        
        % same as below: plottimef(P1-P2, R2-R1, 10*resimages{1}, resimages{2}, mean(data{1},2)-mean(data{2},2), freqs, times, mbase, g);
        if strcmpi(g.plotersp, 'on') | strcmpi(g.plotitc, 'on')
            g.erspmax = []; % auto scale
            g.itcmax  = []; % auto scale
            plottimef_for_2_conditions(10*resdiff{1}, resdiff{2}, 10*resimages{1}, resimages{2}, ...
                mean(data{1},2)-mean(data{2},2), freqs, timesout, meanmbase, [], [], g);
        end;
        R1 = res1{2};
        R2 = res2{2};
        Rdiff = resdiff{2};
        Pboot = { Pboot1 Pboot2 10*resimages{1} };
        Rboot = { Rboot1 Rboot2 resimages{2} };
    end;
    P = { P1 P2 P1-P2 };
    R = { R1 R2 Rdiff };
    
    if nargout >= 8, alltfX = { alltfX1 alltfX2 }; end;
    
    return; % ********************************** END FOR MULTIPLE CONDITIONS
end;
