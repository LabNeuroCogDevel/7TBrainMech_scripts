% EEGLAB history file generated on the 17-Jul-2023
% ------------------------------------------------
addpath(genpath(hera('/Projects/7TBrainMech/scripts/eeg/Shane/resources/eeglab2022.1')))
eeglab

datapath = hera('/Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/AfterWhole/ICAwholeClean_homogenize');

%load in all the data files
setfiles0 = dir([datapath,'/*icapru*.set']);
setfiles = {};

for epo = 1:length(setfiles0)
    setfiles{epo,1} = fullfile(datapath, setfiles0(epo).name); % cell array with EEG file names
    % setfiles = arrayfun(@(x) fullfile(folder, x.name), setfiles(~[setfiles.isdir]),folder, 'Uni',0); % cell array with EEG file names
end

for j = 1 : length(setfiles0)
    idvalues(j,:) = (setfiles0(j).name(1:14));
end

numSubj = length(idvalues);

for i = 1:numSubj

    inputfile = setfiles{i};
    subject = inputfile(105:118);
    filename = inputfile(105:151);
    filepath = inputfile(1:104);

    % load in the subject
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_loadset('filename',filename,'filepath',filepath);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    EEG = eeg_checkset( EEG );

    % epoch the data for trigger '4' aka 40hz
    newname = [filename '_epochs'];
    EEG = pop_epoch( EEG, {  '4'  }, [-0.2 0.5], 'newname', newname, 'epochinfo', 'yes');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off');
    EEG = eeg_checkset( EEG );

    % remove baseline (-200 - 0ms)
    EEG = pop_rmbase( EEG, [-200 0] ,[]);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off');
    EEG = eeg_checkset( EEG );

    % run wavelet
    % [-200 493] is the time of the epochs to run the transformation on
    % [2 7] 2 wavelet cycles at low freq, 7 at high frequencies

    numchannels = 6;
    channels = [4,5,6, 37, 38, 39];

    for c = 1:numchannels
        channel = channels(c);
        figure;
        [ersp,itc,powbase,times,freqs] = pop_newtimef( EEG, 1, channel, [-200  493], [2  7] , 'topovec', channel, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'baseline',[0], 'plotphase', 'off', 'ntimesout', 400, 'padratio', 1, 'winsize', 35);
        EEG = eeg_checkset( EEG );

        eeglab redraw;
        close all;

        oneSubDLPFCs{c} = EEG;

    end

    allSubjectsDLPFCs{i} = oneSubDLPFCs;

end
