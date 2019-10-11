function [channels_removed, data_removed, epochs_removed] = singlesubject(inputfile, lowBP, topBP, outpath, FLAG, varargin)

% addpath(genpath('Functions'));
% addpath(hera('Projects/7TBrainMech/scripts/eeg/toolbox/eeglab14_1_2b'));

%% to run singlesubject one at a time
% -- run me as a function!
% setfiles = dir(hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/remarked/11667*.set'));
% 
% inputfile = [setfiles.folder '/' setfiles.name];
% lowBP = 0.5;
% topBP = 70;
% FLAG = 1;
% outpath = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep');
% singlesubject(inputfile, lowBP, topBP, outpath, FLAG)
%% 

% what file are we using
if ~exist(inputfile,'file'), error('inputfile "%s" does not exist!', inputfile), end
[d, currentName, ext ] = fileparts(inputfile);


% where to find eeglab stuff
eeglabpath = fileparts(which('eeglab'));

%% cap locations
cap_location = fullfile(eeglabpath,'/plugins/dipfit2.3/standard_BESA/standard-10-5-cap385.elp');
if ~exist(cap_location, 'file'), error('cannot find file for 128 channel cap: %s', cap_location), end
correction_cap_location = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Functions/resources/ChanLocMod128to64.ced');
if ~exist(correction_cap_location, 'file'), error('cannot find file for correction 128 channel cap: %s', correction_cap_location), end

%% Files
subj_files = file_locs(inputfile);

% to know how far your script is with running
fprintf('==========\n%s:\n\t singlesubject(%s,%f,%f,%s)\n',...
    currentName, inputfile, lowBP, topBP, outpath)


% where to save things
filter_folder = 'filtered';
chanrj_folder = 'channels_rejected';
epoch_folder = 'epoched';
icawholein_folder ='rerefwhole';
epoch_rj_marked_folder = 'marked_epochs';
epochrj_folder = 'rejected_epochs';
icaout = fullfile(outpath, 'ICA');
icawholeout = fullfile(outpath, 'ICAwhole');

% and what files will we create
rerefwhole_name = [currentName '_rerefwhole'];
chrm_name   = [currentName '_badchannelrj'];
epochrj_name = [currentName '_epochs_rj'];
% FIXME: these is not actually used!? but is recoreded in data_removed WF20190911
datarm_name = [currentName '_baddatarj'];
epochrm_name = [currentName '_badepochrj'];
% TODO: collect other pop_saveset filenames here

commonPlus = {'AFz','C1','C2','C3','C4','C5','C6','CP1','CP2','CP3','CP4',...
    'CP5','CP6','CPz','Cz','F1','F2','F3','F4','F5','F6','F7','F8','FC1',...
    'FC2','FC3','FC4','FC5','FC6','FCz','Fp1','Fp2','FT10','FT9','Fz','I1',...
    'I2','O1','O2','Oz','P1','P10','P2','P3','P4','P5','P6','P7','P8','P9',...
    'PO10','PO3','PO4','PO7','PO8','PO9','POz','Pz','T7','T8',...
    'AF8','AF7','AF4','AF3'};% This 
% check if we've already run subject
% if we have, read in what we need from set file

% dont check if already done
epochrj = fullfile(outpath, epochrj_folder, [epochrj_name '.set']);
% if exist(epochrj, 'file')
%     warning('%s already complete (have "%s")! todo load from file', currentName, epochrj)
%     rj = pop_loadset(epochrj);
%     channels_removed = {chrm_name, rj.channels_rj, find(rj.etc.clean_channel_mask==0)}';
%     data_removed = {datarm_name, rj.data_rj, rj.data_rj_nr}';
%     epochs_removed = {epochrm_name, rj.epoch_rj, rj.epoch_rj_nr}';
%     % ica wont rerun if already run
%     runICAss(epochrj, icaout)
%     % runICAss will skip if fullfile(icaout, [name '_ICA_SAS.set']) already exists
%     return
% end
% 
icawholein = fullfile(outpath, icawholein_folder, [rerefwhole_name '.set']);
if exist(icawholein, 'file')
     warning('%s already complete (have "%s")! todo load from file', currentName, rerefwhole_name)
     return
end
%     % ica wont rerun if already run
%     runICAss(icawholein, icawholeout)
%     return
% end
% allocate cells
channels_removed = cell(3,1,1);
data_removed = cell(3,1,1);
epochs_removed = cell(3,1,1);

xEEG = load_if_exists(subj_files.filter);
if isstruct(xEEG)
    [ALLEEG EEG CURRENTSET] = pop_newset([], xEEG, 0,...
        'setname',currentName,...
        'gui','off');
else
    %load EEG set
    EEG = pop_loadset(inputfile);

    if size(EEG.data,1) < 100
        Flag128 = 0;
        EEG = pop_reref(EEG, [65 66]); %does this "restore" the 40dB of "lost SNR" ? -was it actually lost? ...this is potentially undone by PREP
        EEG = eeg_checkset(EEG);
        % find the cap to use
    else
        %[129 130] are the mastoid externals for the 128 electrode
        EEG = pop_reref(EEG, [129 130]); %does this "restore" the 40dB of "lost SNR" ? -was it actually lost? ...this is potentially undone by PREP
        EEG = eeg_checkset(EEG);
    end

    %stores EEG set in ALLEEG, give setname
    ALLEEG = [];
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,...
        'setname',currentName,...
        'gui','off');

    % split 10129_20180919_mgs_Rem into
    %    subj=10129_20180919    and    condition=mgs_Rem
    EEG.subject = currentName(1:findstr(currentName,'mgs')-2);
    EEG.condition =  currentName(findstr(currentName,'mgs'):end);

    %band-pass filter between low and max boundle (or 1 and 90 Hz)
    % TODO: params are
    %  EEG, locutoff, hicutoff, filtorder, revfilt, usefft, plotfreqz, minphase);
    % why 3380, 0, [], 0
    % > Warning: Transition band is wider than maximum stop-band width.
    % For better results a minimum filter order of 6760 is recommended.
    % Reported might deviate from effective -6dB cutoff frequency.
    % [FLAGexist] = checkdone(fullfile(outpath,filter_folder,[currentName '_filtered']));

   EEG = pop_eegfiltnew(EEG, lowBP, topBP, 3380, 0, [], 0);
   % filtorder = 3380 - filter order (filter length - 1). Mandatory even. performing 3381 point bandpass filtering.
   % pop_eegfiltnew() - transition band width: 0.5 Hz
   % pop_eegfiltnew() - passband edge(s): [0.5 90] Hz
   % pop_eegfiltnew() - cutoff frequency(ies) (-6 dB): [0.25 90.25] Hz
   % pop_eegfiltnew() - filtering the data (zero-phase)
   
   %give a new setname and overwrite unfiltered data
   EEG = pop_editset(EEG,'setname',[currentName '_bandpass_filtered']);

   % %50 hz notch filter: 47.5-52.5
   % EEG = pop_eegfiltnew(EEG, 47.5,52.5,826,1,[],0);

   % Downsample the data to 150Hz using antialiasing filter
   EEG = pop_resample(EEG, 150, 0.8, 0.4); %0.8 is fc and 0.4 is dc. Default is .9 and .2. We dont know why Alethia changed them
   
   % Downsample the data to 512Hz
   % EEGb = pop_resample( EEG, 512);
   EEG = eeg_checkset(EEG);

   %change setname
   EEG = pop_editset(EEG,'setname',[currentName '_filtered']);
   [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
   %save filtered data
   EEG = pop_saveset( EEG, 'filename',[currentName '_filtered'], ...
       'filepath',fullfile(outpath,filter_folder));
   [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
end




%% CHANELS
% remove external channels
EEG = pop_select( EEG,'nochannel',{'EX1' 'EX2' 'EX3' 'EX4' 'EX5' 'EX6' 'EX7' 'EX8' 'EXG1' 'EXG2' 'EXG3' 'EXG4' 'EXG5' 'EXG6' 'EXG7' 'EXG8' 'GSR1' 'GSR2' 'Erg1' 'Erg2' 'Resp' 'Plet' 'Temp'});

[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
%import channel locations

%change this maybe
% eeglab should have already been added with addpath

EEG=pop_chanedit(EEG, 'lookup', cap_location);

if size(EEG.data,1) > 100
    EEG = pop_select( EEG,'channel',commonPlus);
    EEG=pop_chanedit(EEG, 'load', {correction_cap_location 'filetype' 'autodetect'});
    % 128    'AF8' --> 64    'AF6'
    % 128    'AF7' --> 64    'AF5'
    % 128    'AF4' --> 64    'AF2'
    % 128    'AF3' --> 64    'AF1'
    Flag128 = 1;
end
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%% bad channel rejection

%bad channels are in general the channels that you can't save even if you
%reject 5-10% of your datapoints

%different options for channel rejection are displayed. Option 3 is ued.

% %1.look at standard deviation in bar plots and remove the channels
% with big std's --> manual
% stdData = std(EEG.data,0,2);
% figure(idx); bar(stdData)

% %2.kurtosis
% EEG = pop_rejchan(EEG, 'elec',[1:8] ,'threshold',5,'norm','on','measure','kurt');

%3.clean_rawdata
xEEG = load_if_exists(subj_files.chanrj);
originalEEG = EEG;
if isstruct(xEEG)
   [ALLEEG EEG] = eeg_store(ALLEEG, xEEG, CURRENTSET);
else
   EEG = clean_rawdata(EEG, 8, [0.25 0.75], 0.7, 5, 15, 0.3); % we can discuss that
   % vis_artifacts(EEG,originalEEG,'NewColor','red','OldColor','black');
   %change setname
   EEG = pop_editset(EEG,'setname', chrm_name);
   [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

   EEG = pop_saveset( EEG,'filename', chrm_name, ...
       'filepath',sprintf('%s/%s/',outpath,chanrj_folder));
end

xEEG = load_if_exists(subj_files.rerefwhole_name);
if isstruct(xEEG)
    [ALLEEG EEG] = eeg_store(ALLEEG, xEEG, CURRENTSET);
else
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
    if ~any(find(cellfun (@any,regexpi (fieldnames(EEG.etc), 'clean_channel_mask'))));
        EEG.etc.clean_channel_mask=42;
    else
    end

   %save the channels that were rejected in a variable
   channels_removed{1} = chrm_name; %setname
   channels_removed{2} = setdiff({originalEEG.chanlocs.labels},{EEG.chanlocs.labels}, 'stable');
   channels_removed{3} = find(EEG.etc.clean_channel_mask==0);
   %also save the channels that were rejected in the EEG struct
   EEG.channels_rj = channels_removed{2};
   EEG.channels_rj_nr = length(EEG.channels_rj);

   %save the proportion of the dataset that were rejected in a variable
   data_removed{1} = datarm_name; %setname
   data_removed{2} = length(find(EEG.etc.clean_sample_mask==0))/EEG.srate;%
   data_removed{3} = length(find(EEG.etc.clean_sample_mask==0))/length(EEG.etc.clean_sample_mask);%
   %also save the data that were rejected in the EEG struct
   EEG.data_rj    = data_removed{2};
   EEG.data_rj_nr = data_removed{3};

   %% interpolate channels
   
   if Flag128 == 1
       nchan = 64
       ngood = length(EEG.chanlocs)
       %  128 cap doesn't have exactly the same postions as 64
       % remove 4 that are in the wrong place and reinterpret
       % AND interp any bad channels
       % do this by removing the 4 128weirdos
       % from the already trimmed (no bad channels) in EEG.chanlocs

       need_128interp = [2  3  35  36 ];
       % get the names of those to remove
       n128name = {originalEEG.chanlocs(need_128interp).labels};
       % should always be {'AF5','AF1','AF2','AF6'} ??

       % find where they are in current EEG files (if they haven't already been removed)
       n128here_idx = find(ismember({EEG.chanlocs.labels},n128name));
       % keep those that aren't the ones we matched
       % remove from chanlocs, data and update nbcan
       % WARNING -- who knows what else we should have changed to update the set info!
       keep_idx = setdiff(1:ngood, n128here_idx)
       EEG.chanlocs = EEG.chanlocs(keep_idx);
       EEG.data = EEG.data(keep_idx,:);
       EEG.nbchan = length(keep_idx);

       %EEG_i = pop_interp(EEG, interp_ch, 'spherical'); 
       fprintf('%d channels in orig; want to interpolate %d bad and move %d\n',...
          originalEEG.nbchan, nchan - ngood, length(need_128interp))
       EEG_i = pop_interp(EEG, originalEEG.chanlocs, 'spherical'); 

       % 128    'AF7' --> 64    'AF5' In this point channel 2
       % 128    'AF3' --> 64    'AF1' In this point channel 3
       % 128    'AF4' --> 64    'AF2' In this point channel 35   
       % 128    'AF8' --> 64    'AF6' In this point channel 36
       % lines above modify channel information and pocition in data to make 
       %  it the same for 64 and 128 cap
       EEG = EEG_i;
       EEG.chanlocs(2) = EEG_i.chanlocs(3);%EEG.chanlocs(2) must by 'AF1' in 64 cap
       EEG.chanlocs(3) = EEG_i.chanlocs(2);%EEG.chanlocs(3) must by 'AF5' in 64 cap
   %     EEG.chaninfo.filecontent(4,:) = EEG_i.chaninfo.filecontent(3,:); This
   %     is not necessary i think, but just in case... 
   %     EEG.chaninfo.filecontent(4,1) = '3';
   %     EEG.chaninfo.filecontent(3,:) = EEG_i.chaninfo.filecontent(4,:);
   %     EEG.chaninfo.filecontent(3,1) = '2';
       EEG.data(2,:) = EEG_i.data(3,:);% ALERT ALERT Lines latelly added
       EEG.data(3,:) = EEG_i.data(2,:);% ATERT ALERT Lines latelly added
   else
       EEG = pop_interp(EEG, originalEEG.chanlocs, 'spherical');
   end
   % eeglab redraw
   %% re-reference: average reference
   if FLAG
       EEG = pop_reref( EEG, []);
       [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,...
           'setname',[currentName '_avref'],...
           'gui','off');
       
   else
   end

   %save whole rereferenced data for ICA whole
   %save epochs rejected EEG data
   EEG = pop_editset(EEG, 'setname', rerefwhole_name);
   [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

   EEG = pop_saveset(EEG, 'filename', rerefwhole_name, 'filepath', fullfile(outpath,icawholein_folder));
   [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
end

% Whole data ICA run
if ~exist(subj_files.icawhole, 'file')
   runICAss(icawholein, icawholeout)
else
   fprintf('have %s, not rerunning\n', subj_files.icawholeout)
end

%%% epoching: 2 seconds

%%create events
%EEG = eeg_regepochs(EEG,'recurrence',2,'rmbase',NaN,'extractepochs','off');
%[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,...
%    'setname',[currentName '_events'],...
%   'gui','off');

%%extract epochs
%EEG = pop_epoch( EEG, {  'X'  }, [0  2],...
%    'newname', [currentName '_epochs'],...
%    'epochinfo', 'yes');
%[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'overwrite','on','gui','off');

%%save epoched eegsets
%EEG = pop_saveset( EEG,...
%    'filename',[currentName '_epochs'], ...
%    'filepath',sprintf('%s/%s/',outpath,epoch_folder));
%[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
  
  
%% epoching: -0.400 to 2 seconds
%extract epochs
EEG = pop_epoch( EEG, {'-5' '-3' '0' '1' '2' '3' '4' '5'}, [-0.4  2], 'newname', [currentName '_epochs'], 'epochinfo', 'yes');

% %remove baseline
% EEG = pop_rmbase( EEG, [-400    0]);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'overwrite','on','gui','off');

%save epoched eegsets
EEG = pop_saveset( EEG,'filename',[currentName '_epochs'], ...
    'filepath',sprintf('%s/%s/',outpath,epoch_folder));
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%% epoch rejection
xEEG = load_if_exists(subj_files.epochrj);
if isstruct(xEEG)
    [ALLEEG EEG] = eeg_store(ALLEEG, xEEG, CURRENTSET);
else

    % ~10% should be rejected.

    %Two options for epoch rejection: 2nd option is used.

    %1. kurtosis
    %kurtosis (not recommended): default 5 for maximum threshold limit. Try that, check how many
    %epochs removed, otherwise higher to 8-10.
    % EEG = pop_autorej(EEG, 'nogui','on','eegplot','off');

    %2.Use improbability and thresholding
    %Apply amplitude threshold of -500 to 500 uV to remove big
    % artifacts(don't capture eye blinks)
    EEG = pop_eegthresh(EEG,1,[1:EEG.nbchan],-500,500,0,EEG.xmax,0,1);


    %apply improbability test with 6SD for single channels and 2SD for all channels,
    EEG = pop_jointprob(EEG,1,[1:EEG.nbchan],6,2,0,0,0,[],0);

    %save marked epochs (to check later if you agree with the removed opochs)
    EEG = pop_editset(EEG,'setname',[currentName '_epochs_marked']);
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

    EEG = pop_saveset( EEG,'filename',[currentName '_epochs_marked'], ...
        'filepath',fullfile(outpath, epoch_rj_marked_folder));
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

    %save the epochs that were rejected in a variable
    epochs_removed{1} = epochrm_name; %setname
    epochs_removed{2} = length(find(EEG.reject.rejjp))/EEG.trials;
    epochs_removed{3} = length(find(EEG.reject.rejjp));
    %also save the epochs that were rejected in the EEG struct
    EEG.epoch_rj = epochs_removed{2};
    EEG.epoch_rj_nr = epochs_removed{3};

    %reject epochs
    EEG = pop_rejepoch(EEG, find(EEG.reject.rejjp), 0);

    %save epochs rejected EEG data
    EEG = pop_editset(EEG, 'setname', epochrj_name);
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

    EEG = pop_saveset(EEG, 'filename', epochrj_name, 'filepath', fullfile(outpath,epochrj_folder));
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

end

%% run ICA
% replaced with `rjpath`
%[~, subjname, ~] = fileparts(setfiles{i})
% rjpath = fullfile(outpath, epochrj_folder, [sujname, '*']);
if exist(subj_files.icaout, 'file')
  runICAss(epochrj, icaout)
end
