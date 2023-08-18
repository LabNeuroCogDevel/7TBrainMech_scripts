
% extracting one channel of data from resting state from one adult and one
% child for brown collab

addpath(genpath('Functions'));
addpath(genpath(hera('/Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master/')))
addpath(hera('/Projects/7TBrainMech/scripts/fieldtrip-20191213'))
ft_defaults

datapath = hera('/Projects/7TBrainMech/scripts/eeg/Shane/Resting_State/AfterWhole/ICAwholeClean_homogenize');

%load in all the delay files
setfiles0 = dir([datapath,'/*icapru.set']);
setfiles = {};

for epo = 1:length(setfiles0)
    setfiles{epo,1} = fullfile(datapath, setfiles0(epo).name); % cell array with EEG file names
    % setfiles = arrayfun(@(x) fullfile(folder, x.name), setfiles(~[setfiles.isdir]),folder, 'Uni',0); % cell array with EEG file names
end

for j = 1 : length(setfiles0)
    
    idvalues(j,:) = (setfiles0(j).name(1:14));
end

numSubj = length(idvalues);
x = cell(1,numSubj);
subject = cell(1,numSubj);

clear x
clear Subjects

% i = 79 is for the adult example (11674_20210714)
 
for i = 79
    inputfile = setfiles{i};
    subject{i} = inputfile(95:108);

    if any(strcmp(alreadyRun, subject{i}))
        warning('%s already complete', subject{i})
        continue

    else

        clear events
        clear data
        clear hdr
        clear avgData
        clear classLabels
        clear allData
        clear ChannelTrialData

        hdr = ft_read_header(inputfile);
        data = ft_read_data(inputfile, 'header', hdr);
        events = ft_read_event(inputfile, 'header', hdr);

        cfg = [];
        cfg.dataset = inputfile;
        cfg.headerfile = inputfile;
        cfg.channel =   {'F5'};
        cfg.trialdef.eventtype = 'trigger';
        cfg.trialdef.eventvalue = '16129';
        cfg.trialdef.prestim = 0;
        cfg.trialfun = 'ft_trialfun_general';
        cfg.event = events;

        if ~ischar(cfg.event(1).value)

            newevents = cfg.event;
            for j = 1:length(newevents)
                newevents(j).value = num2str(newevents(j).value);
            end
            cfg.event = newevents;

        end

        try

            [cfg]= ft_definetrial(cfg);

        catch
            warning('%s wont run through feildtrip', subject{i})
            wontRun{i} = subject{i};
            continue;
        end

        cfg.continuous = 'no';
        cfg.checkmaxfilter = 'true';
        [data] = ft_preprocessing(cfg);


        %redefine the trails to be between 3-4 seconds of the delay period
        cfg.trl = [];
        cfg = rmfield(cfg, 'trl');        
        cfg.toilim = [3 4];
        data = ft_redefinetrial(cfg, data);

        for j = 1:length(data.trial) %trial

            trialData = (data.trial{1,j});
            ChannelTrialData{j} = trialData(:,:);

        end

        %     avgData = squeeze(mean(allData, 1));

        x{i} = ChannelTrialData;
        additionalSubject{i} = inputfile(95:108);

    end

end