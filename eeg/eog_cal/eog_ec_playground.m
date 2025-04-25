%TIME UNIT IS SECONDS!!!!!! NOT MILLISECONDS!
%% load tools into workspace
addpath('/home/ni_tools/matlab_toolboxes/fieldtrip-20180926/');
ft_defaults

%%get subjects
fname='/Volumes/Hera/Raw/EEG/Habit/11952_20230706/11952_20230706_dr.bdf';
calname='/Volumes/Hera/Raw/EEG/Habit/11952_20230706/11952_20230706_eyecal.bdf';

anti_data = bdf_read_chnl(fname,{'Status','horz_eye'});
calibration_data = bdf_read_chnl(calname,{'Status','horz_eye'});

VERBOSE = 0; MAKEFIGS = 0; SAVEFIGS = 0;

%%
d=anti_data;
% Get left - right
eyeDiff = d.eye_l - d.eye_r;


% find trial onsets
statusOnsetInds = find(diff(d.Status) >0)+1;
statusOnsets = d.Status(statusOnsetInds);

is_reward_dot=statusOnsets>240 & statusOnsets<247;
is_neutral_dot=statusOnsets>140 & statusOnsets<147;

startind = find(is_reward_dot|is_neutral_dot);
trialOnsets = statusOnsets(startind);
trialOnsetInds = statusOnsetInds(startind);

%Get lunaid and visit date
matches = regexp(fname,'\d{5}_\d{8}','match');
splitstr=split(matches{1}, '_');
lunaid = splitstr{1};
vdate = splitstr{2};

% confirm
%[trialOnsetInds' trialOnsets' d.Status(trialOnsetInds)']
nTrials = length(startind);
fprintf('Found %d trials\n', nTrials);
%triali = 40;

%%
close all
FILTER_WIDTH = 50;
% constants
Gd = FILTER_WIDTH/2; 
w = gausswin(FILTER_WIDTH);
w = w./sum(w);

% Get left - right
%sub out 1 to look at other saccades besides the first one! visualize with
%plot below 
inds=(trialOnsetInds(40)-100):(trialOnsetInds(40)+500);
eyeDiff = d.eye_l - d.eye_r;
eogTS = eyeDiff(inds);
PRETASK_DURATION=(100/d.Fs); % 100 samples at d.Fs frequency

%what is the stim channel value for that specific saccade?
dot_index = trialOnsetInds(56)
event_trigger = d.Status(dot_index)

% normalize position to pre task fixation (un-drift)
meanPretask = mean(eogTS(1:round(PRETASK_DURATION*d.Fs)));
eogTS = eogTS - meanPretask;
eogSm = filtfilt(w,1,eogTS);

%for calibration (aligning individual subject to their calibration slope
%volts/distance)
cal = make_cal(calname, VERBOSE, MAKEFIGS);
            
 velThresh = 30 * abs(cal.slope) / d.Fs; %fixVel*12;

 eogTS_cal = [eogTS]/cal.slope
 
 %% plot together a single saccade
 plot(0:600, eogTS)
 hold on
 plot(0:600, eogSm)
 
 figure
 
 %plot all saccades for a single trial
 plot (eyeDiff)
 hold on
 plot (d.Status)
 
%% diff then integrate (remove intercept?)
eogSm_orig = eogSm;
vel = diff(eogSm);%filter(w,1,diff(eogSm));
vel_detrend = vel - median(vel);
eogSm_integral = cumsum(vel_detrend); eogSm_integral(end+1) = eogSm_integral(end);
eogSm = eogSm_integral;

plot(eogSm_integral)

samplerange=101:600;
%samplerange=antInd:itiInd;
% NB. follow like score_eog w/target<->iti interval.
% but expected to use cueInd:antInd instead
fixVel = median(abs(vel(samplerange)));
velThresh = fixVel*12;


% get saccade latency
eogsm_t = eogSm(samplerange);
 %   [antilat, meanEOG, VelDisplacement, saccades] = eog_sacs_ec(eogsm_t, velThresh, Gd, d.Fs);
    

    

%% 20241219 - WF using score_anti_trial
cal = make_cal(calname, 0, 0); % read but dont plot, not verbose

%trial_i = 42; error corrected trial
run_output = cell(1,length(trialOnsetInds));
for trial_i = 1:length(trialOnsetInds)
    dot_start = trialOnsetInds(trial_i);
    dot_end = dot_start+1*d.Fs; % only look at first second of event
    % on left, look right 1 2 3; on right, look left: 4 5 6
    if mod(d.Status(dot_start),10) > 3
        trial_sign=-1;
    else
        trial_sign=1;
    end
    pre_trial_samples = 100;
    trial_ts = eyeDiff((dot_start - pre_trial_samples):dot_end);

    [lat, score, tinfo] = score_trial(trial_ts, trial_sign, cal.slope, pre_trial_samples, FILTER_WIDTH, d.Fs);
    run_output{trial_i} = tinfo;
end

%cellfun(@(x) 1*x.score,run_output) check score output
score_outcomes = cellfun(@(x) 1*x.score,run_output)
hist(score_outcomes)

%% plot
    plot(tinfo.eogSm)
    hold on
    plot(tinfo.vel_detrend)
    xline(tinfo.stim_onset_ind, 'g')
    yline([-1,1].*tinfo.velThresh,'y')
    plot(tinfo.saccades+tinfo.stim_onset_ind,tinfo.eogSm(tinfo.saccades+tinfo.stim_onset_ind),'k.')
    yline(tinfo.meanEOG,'b')
    yline(tinfo.second_end,'r')
    
    hold off

 return
 
%% score all sessions, all ppts
maindir = '/Volumes/Hera/Raw/EEG/Habit/';
subjinfo = dir(maindir);
subjinfo([1:2,159],:)=[];

drstring = '*_dr.bdf';
calstring = '*_eyecal.bdf';

for d = 1:size(subjinfo)
    folder = subjinfo(d).name
    path=[maindir,folder, '/'];
    addpath(path)
  
    drfile = dir([path, drstring]);
    calfile = dir([path, calstring]);
    
    if isempty(drfile)
        fprintf('Error: NO DRFILE for %s\n', folder)
        continue
    elseif isempty(calfile)
        fprintf('Error: NO CALFILE for %s\n', folder)
        continue
    end
    
    fname = [drfile.folder, '/', drfile.name];
    calname = [calfile.folder, '/', calfile.name];
    
 %Get lunaid and visit date
    matches = regexp(fname,'\d{5}_\d{8}','match');
    splitstr=split(matches{1}, '_');
    lunaid = splitstr{1};
    vdate = splitstr{2};
   
   [all_tinfo{d},all_ppt_output{d}] = score_session(fname, calname);
   
   for tinfo= all_tinfo{d}
       tinfo=tinfo{1}
       %plot_tinfo(tinfo)
       %hgexport(gcf, sprintf('/tmp/%s_%s_%d_tinfo.png',lunaid, vdate, tinfo.trial_i));
   end
end

%% Convert all_ppt_output 1x157 cell array to table
all_ppt_table=table();
for i=1:length(all_ppt_output)
    all_ppt_table=[all_ppt_table;array2table(all_ppt_output{i})];
end

all_ppt_table.Properties.VariableNames = {'lunaid', 'vdate', 'lat', 'score', 'stim_chan_code'};

% Write the table to a CSV file
writetable(all_ppt_table,'all_ppt_table.csv')

