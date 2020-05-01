% saves mat to trial_data/anti
% and returns matrix like
%   subjid date trialnum xdat correctsaccade lat eog/slope veldisp/slope calr2 calslope
%
% score a subject's anti state eeg
%   using score_eog.m (VGS/MGS score) as reference
%
%
%  --- xdats ---
% from anti task data
% unique(d.Status)
%   0   101   102   104   105   151   152   154   155   254
% histc(d.Status(d.Status>0), unique(d.Status))
%        62    62    63    60    61    61    62    61   251
%
% 101-105 = anti cue
% 151-155 = target (dot on, look away)
% 254     = back to fixation
%
% 20200501 WF - init

function thisdata = score_anti(subj)
% e.g. subj='11630_20191119'

% SETTINGS
PRETASK_DURATION = .3; % seconds
POSTONSET_DURATION = 30; % seconds
FILTER_WIDTH = 50;

% preferences
MAKEFIGS=0;
VERBOSE=0;
SAVEFIGS=0;
thisdata=[];

% constants
Gd = FILTER_WIDTH/2; 
w = gausswin(FILTER_WIDTH);
w = w./sum(w);

% setup fieldtrip
if isempty(which('ft_defaults'))
    addpath('/home/ni_tools/matlab_toolboxes/fieldtrip-20180926/');
end
ft_defaults

% subject info
parts = strsplit(subj, '_');
subjid = parts{1};
scandate = parts{2};

% try loading data
fprintf('Processing subject %s %s %s\n', subj, subjid, scandate);
try
    fprintf(1, 'Loading mgs for %s\n', subj);
    d=eeg_data('#anti', {'Status','horz_eye'}, 'subjs', {subj});
catch
    fprintf(1, '--> %s: Could not load Anti data, skipping\n', subj);
    return;
end
try
    cal = make_cal(subj, 0, 0);
catch
    fprintf(1, '--> %s: Could not load calibration data, skipping\n', subj);
    return;
end

% merge in case of more than one run
if length(d)>1
    newd = d(1);
    newd.Status = [d.Status];
    newd.eye_l = [d.eye_l];
    newd.eye_r = [d.eye_r];
    d = newd;
    clear newd;
end

% Get left - right
eyeDiff = d.eye_l - d.eye_r;


% find trial onsets
statusOnsetInds = find(diff(d.Status) >0)+1;
statusOnsets = d.Status(statusOnsetInds);

startind = find(statusOnsets>100 & statusOnsets<110);
trialOnsets = statusOnsets(startind);
trialOnsetInds = statusOnsetInds(startind);

% confirm
%[trialOnsetInds' trialOnsets' d.Status(trialOnsetInds)']
nTrials = length(startind);
fprintf('Found %d trials\n', nTrials);
%triali = 40;

%% score each trial
for triali = 1:nTrials
    
    % find trial samples
    % get a smig before trial starts (PRETASK_DURATION)
    first = max(1, round(trialOnsetInds(triali) - PRETASK_DURATION*d.Fs));
    % make sure no other codes in PRETASK_DURATION
    assert(unique(d.Status(first:(trialOnsetInds(triali)-1))) == 0, 'PRETASK_DURATION goes too far!');
    % find last index of this trial
    if triali < nTrials
        last = trialOnsetInds(triali+1)-1;
    else
        last = length(d.Status);
    end
    inds = first:last;

    % get data intervals
    statusTS = d.Status(inds);
    intInds = find(diff(statusTS)>0)+1;
    intCodes = statusTS(intInds);

    cueInd = intInds(find(intCodes>=100 & intCodes<110, 1, 'first'));
    antInd = intInds(find(intCodes>=150 & intCodes<200 & intCodes~=128 & intInds>cueInd, 1, 'first'));
    itiInd = intInds(find(intCodes==254 & intInds>cueInd, 1, 'first'));
    if isempty(itiInd)
        itiInd = length(inds)-1;
        intCodes,
        fprintf('%s %d: warning no final itiInd using %d - %d (%.2f secs)\n', ...
                subj, triali, cueInd, itiInd, (itiInd-cueInd)/d.Fs)
    end

    if isempty(cueInd) || isempty(antInd) || isempty(itiInd)
        fprintf(1, '--> %s, trial %d: missing index, skipping\n', subj, triali);
        return;
    end
    
    if VERBOSE
        [cueInd antInd itiInd]
    end


    % extract timecourse
    eogTS = eyeDiff(inds);

    % normalize position to pre task fixation (un-drift)
    meanPretask = mean(eogTS(1:round(PRETASK_DURATION*d.Fs)));
    eogTS = eogTS - meanPretask;
    eogSm = filter(w,1,eogTS);
    

    % diff then integrate (remove intercept?)
    eogSm_orig = eogSm;
    vel = diff(eogSm);%filter(w,1,diff(eogSm));
    vel_detrend = vel - median(vel);
    eogSm_integral = cumsum(vel_detrend); eogSm_integral(end+1) = eogSm_integral(end);
    eogSm = eogSm_integral;
    
    % visualize
    if MAKEFIGS
        dur = length(inds)/d.Fs;
        t = linspace(-PRETASK_DURATION*d.Fs, dur, dur*d.Fs);
        set(gcf, 'Position', [324         793        1371         2*449]);
        set(gcf, 'color', 'w');
        
        subplot('position', [0.05 .55 .9 .4]);
        plot(t, statusTS, 'b')
        hold on
        plot(t, eogTS, 'g')
        plot(t-Gd/d.Fs, eogSm_orig, 'k')
        plot(t-Gd/d.Fs, [0 vel]*max(eogSm)/(2*max(vel)), 'r')

        plot(t-Gd/d.Fs, eogSm, 'm')
        
        statusTSinds = (find(diff(statusTS)>0)+1);
        labels = statusTS(statusTSinds);
        for i = 1:length(labels)
            text(statusTSinds(i)/d.Fs - PRETASK_DURATION - 150/d.Fs, -50, sprintf('%d', labels(i)));
        end
    end


    % get median velocity distribution between cue and anti
    samplerange=antInd:itiInd;
    % NB. follow like score_eog w/target<->iti interval.
    % but expected to use cueInd:antInd instead
    fixVel = median(abs(vel(samplerange)));
    velThresh = fixVel*12;


    % get saccade latency
    eogsm_t = eogSm(samplerange);
    [antilat, meanEOG, VelDisplacement, saccades] = eog_sacs(eogsm_t, velThresh, Gd, d.Fs);
    if isempty(saccades)
        fprintf('no data in %s trial %d (%d)', subj, triali, intCodes(1))
    end
    
    % 102 and 103 are left. but should have looked right
    iscorrect = 1.*(sign(103 - intCodes(1)) == sign(meanEOG/cal.slope));
    % no saccades found? drop it
    iscorrect(~isfinite(antilat)) = NaN;
    
    thisdata(end+1,:) = [str2double(subjid) str2double(scandate)...
                         triali intCodes(1) ...
                         antilat ...
                         iscorrect ...
                         meanEOG/cal.slope ...
                         VelDisplacement/cal.slope ...
                         cal.r2 cal.slope];
    
end

%% --- Save
subjdatafile = sprintf('trial_data/anti/%s_%s.mat', subjid, scandate);
save(subjdatafile, 'thisdata');
fprintf('\tProcessed %d trials\n', size(thisdata,1));


end

