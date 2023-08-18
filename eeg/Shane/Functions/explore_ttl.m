
%% setup paths
addpath(genpath('Functions'));
addpath(hera('/Projects/7TBrainMech/scripts/fieldtrip-20191127'))
addpath(hera('Projects/7TBrainMech/scripts/eeg/eog_cal'))
ft_defaults

%% quick illiusration of problem
inputfile = hera('Raw/EEG/7TBrainMech/10129_20180919/10129_20180919_rest.bdf');
% fieldtrip
hdr = ft_read_header(inputfile);
ft_data = ft_read_data(inputfile, 'header', hdr);
ft_events = ft_data(73,:); % 'Status' channel is 73rd
ft_events2 = ft_read_event(inputfile, 'header', hdr);
% eeglab
el_EEG = pop_biosig(inputfile);
el_events = [el_EEG.event.type];

%% compare
unique([ft_events2.values]),
%  -6799616    -6799615    -6799614    -6799516    -6799515    -6799488    -6799416    -6799415    -6799414
%  -6799388    -6734080    -6733952
unique(el_events),
% 16129       16130       16229       16256       16328       16329       16330       16356

unique(fix_status_channel(ft_events)),
% 0     1     2   100   101   128   200   201   202   228
unique(fix_status_channel(el_events)),
% 0     1   100   127   199   200   201   227

%% Find a raw example
% outputpath = hera('Projects/7TBrainMech/scripts/eeg/Shane/Resting_State/remarked');
allraw = dir(hera('Raw/EEG/7TBrainMech/Raw/EEG/7TBrainMech/1*_2*/1*_2*_*bdf'));
restIDX = find(~cellfun(@isempty,regexpi({namesOri.name}.', 'rest')));
i=restIDX(1);
inputfile = fullfile(namesOri(i).folder, namesOri(i).name);
% inputfile ='/Volumes/Hera/Raw/EEG/7TBrainMech/10129_20180919/10129_20180919_rest.bdf';

%% read in data with fieldtrip. not useful?
hdr = ft_read_header(inputfile);
status_ch_idx = find_status_channel(hdr.label); % 73
data = ft_read_data(inputfile, 'header', hdr);
%% fix trigger value (ttl) "mark"
data(status_ch_idx,:) = fix_status_channel(data(status_ch_idx,:));
% unique(data(status_ch_idx,:))
%     0     1     2   100   101   128   200   201   202   228 

% addpath(hera('Projects/7TBrainMech/scripts/eeg/toolbox/eeglab14_1_2b/functions/miscfunc'))
% EEG = fieldtrip2eeglab(hdr, data, []);

%% ft read events. require file as input. so make a temporary one
tname = [tempname() '.edf']
ft_write_data(tname, data, 'header', hdr, 'dataformat','edf')
newd = ft_read_data(tname);
events = ft_read_event(tname, 'chanindx', status_ch_idx)
% 20201216 - events are empty :(
delete(tname)

%% with eeglab
EEG = pop_biosig(inputfile);
% Status channel doesnt exist anymore
% eeg_ch_idx = find_status_channel({EEG.chanlocs.labels}); % 73
EEG_w_events = lncd_triggers(EEG);
eeglab_events = unique([EEG_w_events.event.type]),
%
%eeglab_events =
%     0     1   100   127   199   200   201   227


%% look at eyes open/closed by trigger
d = bdf_read_chnl(inputfile, {'horz_eye'}, hdr);
s = bdf_read_chnl(inputfile, {'Status'}, hdr);
status = s.Status;
status(find(diff(status)==0)+1) = 0;
i=find(status~=0);
events=[i', status(i)'];
