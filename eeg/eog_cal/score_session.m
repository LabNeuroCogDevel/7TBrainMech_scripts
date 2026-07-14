function [run_output, ppt_output] = score_session(fname,calname, opt)
%Score session Summary of this function goes here
%   Detailed explanation goes here
arguments
   fname
   calname
   opt.CSVOutputFile char
   opt.histplot logical = false
end

% constants
FILTER_WIDTH = 50;

% need fieldtrip to read data. if we can't find it, try to load it
if isempty(which('ft_read_header'))
   addpath('/home/ni_tools/matlab_toolboxes/fieldtrip-20180926/');
   ft_defaults
end

try 
  anti_data = bdf_read_chnl(fname,{'Status','horz_eye'});
catch e
   disp(e)
   run_output = {}; ppt_output = [];
   return
end

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

%% 20241219 - WF using score_anti_trial
cal = make_cal(calname, 0, 0); % read but dont plot, not verbose

%trial_i = 42; error corrected trial
run_output = cell(1,length(trialOnsetInds));
for trial_i = 1:length(trialOnsetInds)
    dot_start = trialOnsetInds(trial_i);
    dot_end = dot_start+1*d.Fs; % only look at first second of event
    % on left, look right 1 2 3; on right, look left: 4 5 6
    stim_chan_code = d.Status(dot_start);
    if mod(stim_chan_code,10) > 3
        trial_sign=-1;
    else
        trial_sign=1;
    end
    pre_trial_samples = 100;
    trial_ts = eyeDiff((dot_start - pre_trial_samples):dot_end);

    [lat, score, tinfo] = score_trial(trial_ts, trial_sign, cal.slope, pre_trial_samples, FILTER_WIDTH, d.Fs);
    tinfo.stim_chan_code = stim_chan_code;
    tinfo.trial_i = trial_i;
    run_output{trial_i} = tinfo;
    %ppt_output = cell(1,length(trialOnsetInds));
    ppt_output(trial_i, :) = [str2double(lunaid), str2double(vdate), lat, score, stim_chan_code];
    %ppt_output(trial_i, :) = [lunaid, vdate, lat, score];
    
end

%check every score output
score_outcomes = cellfun(@(x) 1*x.score,run_output);

if ~isempty(opt.CSVOutputFile)
    disp(['saving to ' opt.CSVOutputFile])
    %convert 56x4 cell array to table. add filename as for posterity
    single_ppt_table=array2table(ppt_output);
    single_ppt_table.Properties.VariableNames = {'lunaid', 'vdate', 'lat', 'score', 'stim_chan_code'};
    single_ppt_table.fname = repmat(fname,height(single_ppt_table),1);
    % Write the table to a CSV file
    writetable(single_ppt_table,opt.CSVOutputFile);
if opt.histplot
    hist(score_outcomes);
end
end
