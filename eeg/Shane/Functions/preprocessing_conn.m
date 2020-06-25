% function [ EEG ] = preprocessing_conn( varargin )
% preprocessing_conn( EEG,lowBP,topBP,FLAG )
%% this script cleans resting data by the following method:
%EEG is the file directory of the EEG data 
% EEG = varargin{1}; 
%bandpass filter:1-90 Hz, or fom lowBP to topBP
% lowBP = varargin{2} ; topBP =  varargin{3} ;
%notch filter: 47.5-52.5 Hz / I usually do not do that if the setting of
%the room is ok. But check out
% Decision point with stop
% Would you like to visually scroll data to reject? If not here implemented  
%channel rejection: clean_rawdata plugin (based on atifact subspace reconstruction with ICA)
%Channel interpolation
%average referencing: FLAG = 1
% FLAG =  varargin{4} ;

%epochs: 2 seconds
%epoch rejection: 
% 1.remove big artifacts with threshold (-500,500 uV) 2.
%   improbability test  (6SD for single channels and 2SD for all channels)
%   --> not really satisfied with this epoch rejection method for my data 
%   (the conscious access data

%the output of this script are EEG data sets that are ready for ICA
%computation (see script 'runICA_dmt')

%% folders to save files

% outpath =   varargin{5} ;
filter_folder = 'filtered';
chanrj_folder = 'channels_rejected';
epoch_folder = 'epoched';
epoch_rj_marked_folder = 'marked_epochs';
epochrj_folder = 'rejected_epochs';

%% load all the EEG file names
%directory of EEG data
[path,folder] = fileparts(EEG);
d =[path,'\',folder,'\'];
% d ='/Users/macbookpro/Documents/MBCS/BA/DMT_experiment/drive-download-20190719T191352Z-001/';
names = dir([d,'*.bdf']);
names = {names(~[names.isdir]).name}; %cell array with EEG file names

%create empty variables
channels_removed = cell(3,size(names,2),1);

%load eeglab
eeglab

%% cleaning

nr_eegsets = size(names,2); %number of EEG sets to preprocess

for idx = 4%1:nr_eegsets
   
currentName = names{idx}(1:end-4);    

%to know how far your script is with running
disp(currentName)
    
%load EEG set
EEG = pop_biosig([d currentName '.bdf'],'ref',[65 66] );

%stores EEG set in ALLEEG, give setname
ALLEEG = [];
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,...
    'setname',currentName,...
    'gui','off'); 

EEG.subject = lower(d(findstr(d,'subj'):end-1));
EEG.condition = upper(currentName(max(findstr(currentName,'_'))+1:end));

%band-pass filter between low and max boundle (or 1 and 90 Hz)
EEG = pop_eegfiltnew(EEG, lowBP,topBP,3380,0,[],0);

%give a new setname and overwrite unfiltered data
EEG = pop_editset(EEG,...
    'setname',[currentName '_bandpass_filtered']);

% %50 hz notch filter: 47.5-52.5
% EEG = pop_eegfiltnew(EEG, 47.5,52.5,826,1,[],0);
    
%change setname
EEG = pop_editset(EEG,...
    'setname',[currentName '_filtered']);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
 
%save filtered data
EEG = pop_saveset( EEG, ...
    'filename',[currentName '_filtered'], ...
    'filepath',sprintf('%s/%s/',outpath,filter_folder));
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    

%% CHANELS
% remove external channels
EEG = pop_select( EEG,'nochannel',{'EX1' 'EX2' 'EX3' 'EX4' 'EX5' 'EX6' 'EX7' 'EX8'});
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); 
%import channel locations

%change this maybe
% EEG=pop_chanedit(EEG, 'lookup','C:\Users\Amelie\Documents\toolbox\eeglab14_1_2b\\plugins\\dipfit2.3\\standard_BESA\\standard-10-5-cap385.elp','changefield',{67 'X' '-65.5'},'changefield',{67 'X' '80'},'changefield',{67 'Y' '46'},'changefield',{67 'Z' '-54'},'convert',{'cart2all'},'changefield',{68 'X' '80'},'changefield',{68 'Y' '-46'},'changefield',{68 'Z' '-54'},'convert',{'cart2all'},'changefield',{69 'X' '80'},'changefield',{69 'Y' '-26'},'changefield',{69 'Z' '-84'},'convert',{'cart2all'},'changefield',{70 'X' '80'},'changefield',{70 'Y' '-26'},'changefield',{70 'Z' '-24'},'convert',{'cart2all'},'changefield',{71 'X' '90'},'changefield',{71 'Y' '0'},'changefield',{71 'Z' '-54'},'convert',{'cart2all'},'changefield',{72 'X' '0'},'changefield',{72 'Y' '0'},'changefield',{72 'Z' '0'},'convert',{'cart2all'}); 
EEG=pop_chanedit(EEG, 'lookup','C:\\Users\\Amelie\\Documents\\toolbox\\eeglab14_1_2b\\plugins\\dipfit2.3\\standard_BESA\\standard-10-5-cap385.elp');
% EEG=pop_chanedit(EEG, 'load',{'C:\\Users\\Amelie\\Documents\\LNCDpasantia\\miniBatchs\\Functions\\resources\\BioSemi64.loc' 'filetype' 'autodetect'});

[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%% bad channel rejection

%bad channels are in general the channels that you can't save even if you
%reject 5-10% of your datapoints

%different options for channel rejection are displayed. Option 3 is ued.

% %1.look at standard deviation in bar plots and remove the channels
%with big std's --> manual
% stdData = std(EEG.data,0,2); 
% figure(idx); bar(stdData)

% %2.kurtosis
% EEG = pop_rejchan(EEG, 'elec',[1:8] ,'threshold',5,'norm','on','measure','kurt');

%3.clean_rawdata
originalEEG = EEG;
EEG = clean_rawdata(EEG, 8, [0.25 0.75], 0.7, 5, 15, 0.3); % we can discuss that
% vis_artifacts(EEG,originalEEG,'NewColor','red','OldColor','black'); 
%change setname
EEG = pop_editset(EEG,...
    'setname',[currentName '_badchannelrj']);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);


EEG = pop_saveset( EEG,...
    'filename',[currentName '_badchannelrj'], ...
    'filepath',sprintf('%s/%s/',outpath,chanrj_folder));
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%save the channels that were rejected in a variable
channels_removed{1,idx} = [currentName '_badchannelrj']; %setname
channels_removed{2,idx} = setdiff({originalEEG.chanlocs.labels},{EEG.chanlocs.labels}, 'stable');
channels_removed{3,idx} = find(EEG.etc.clean_channel_mask==0);
%also save the channels that were rejected in the EEG struct
EEG.channels_rj = setdiff({originalEEG.chanlocs.labels},{EEG.chanlocs.labels}, 'stable');
EEG.channels_rj_nr = length(setdiff({originalEEG.chanlocs.labels},{EEG.chanlocs.labels}, 'stable'));

%% interpolate channels

EEG = pop_interp(EEG, originalEEG.chanlocs, 'spherical');

% eeglab redraw
%% re-reference: average reference

EEG = pop_reref( EEG, []);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,...
    'setname',[currentName '_avref'],...
    'gui','off'); 


%% epoching: 2 seconds
%create events
EEG = eeg_regepochs(EEG,'recurrence',2,'rmbase',NaN,'extractepochs','off');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,...
    'setname',[currentName '_events'],...
    'gui','off');

%extract epochs
EEG = pop_epoch( EEG, {  'X'  }, [0  2],...
    'newname', [currentName '_epochs'],...
    'epochinfo', 'yes');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'overwrite','on','gui','off');

%save epoched eegsets
EEG = pop_saveset( EEG,...
    'filename',[currentName '_epochs'], ...
    'filepath',sprintf('%s/%s/',outpath,epoch_folder));
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
%% epoch rejection

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
EEG = pop_editset(EEG,...
    'setname',[currentName '_epochs_marked']);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

EEG = pop_saveset( EEG,...
    'filename',[currentName '_epochs_marked'], ...
    'filepath',sprintf('%s/%s/',outpath,epoch_rj_marked_folder));
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%reject epochs
EEG = pop_rejepoch( EEG, find(EEG.reject.rejjp) ,0);

%save epochs rejected EEG data
EEG = pop_editset(EEG,...
    'setname',[currentName '_epochs_rj']);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

EEG = pop_saveset( EEG,...
    'filename',[currentName '_epochs_rj'], ...
    'filepath',sprintf('%s/%s/',outpath,epochrj_folder));
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);


end


save([outpath,'/channels_removed.mat'],'channels_removed')

% end