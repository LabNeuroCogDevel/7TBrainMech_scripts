function [] = runICAs(inpath, outpath, varargin)
%% this script runs ICA on all filtered/cleaned/epoched EEG dmt data.
% PCA is used to decrease the number of components 
% inpath like ....rerefwhole/*_rerefwhole.set
% ouptath like .../ICAwhole/
% varargin can contain 'redo' to ignore file already done


% could use files from file_locs instead of defining here
files = file_locs(inpath);

% -- icawhole defined elswhere like:
% icawholeout = fullfile(outpath, 'ICAwhole');


%% find file
% if no file, try searching with *.set
if exist(inpath,'file')
   EEGfileNames = dir(inpath);
else
   EEGfileNames = dir([inpath, '*.set']);
end
currentEEG = EEGfileNames(1).name;
[~, name, ext] = fileparts(currentEEG);

% did we already run? 
% 20191220 - never creates, ICA_SAS code commented out -- why?!
%          - instead we'll check for the actual final file _ICA.set
finalout = files.icawhole;
if exist(finalout, 'file') && ~isempty(strncmp('redo', varargin, 4))
   warning('already created %s, not running. add "redo" to ICA call to redo', finalout)
   return
end

%% run ICA
eeglab

% load data to get bad channels and check channel #
EEG = pop_loadset('filename', currentEEG, 'filepath', fileparts(inpath));
% TODO: just use clean_channel_mask
schans = {name, EEG.channels_rj, find(EEG.etc.clean_channel_mask==0)}';
badchans = schans{3,1};

% if size(EEG.data,1) > 100
%    error('not 64 channel, not sure positions, skipping')
% end

disp(currentEEG);

%control for rank defficiency: if you want to analyse components as
%(and not only use the components to remove noise) you should keep the
%nr of components contstant across datasets. But there should not be
%more components than channels. (So check how many channels are removed).

%     PCAnr = 15; %for example 10 components because in 1 dataset 14 channels were removed
%     %PCAnr = EEG.nbchan - EEG.channels_rj_nr; %or if you are not interested
%     %in component analysis but want to use ICA only for artifact removal
%     %change the PCAnr for each dataset individually

ALLEEG = [];
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', name, 'gui','off');

% %% SASICA Command
% pop_runica
% %Then the user would pull up ICA'd results, and run SAS:
% EEG = eeg_SASICA(EEG, ...
%     'MARA_enable',0, ...
%     'FASTER_enable',0,...
%     'FASTER_blinkchanname','EX5', ...
%     'ADJUST_enable',0,...
%     'chancorr_enable',1,...
%     'chancorr_channames','No channel',...
%     'chancorr_corthresh','auto 4',...
%     'EOGcorr_enable',0,...
%     'EOGcorr_Heogchannames','No channel', ...
%     'EOGcorr_corthreshH','auto 4',...
%     'EOGcorr_Veogchannames','No channel',...
%     'EOGcorr_corthreshV','auto 4',...
%     'resvar_enable',0,...
%     'resvar_thresh',15,...
%     'SNR_enable',1,...
%     'SNR_snrcut',1,...q
%     'SNR_snrBL',[-Inf 0] ,...
%     'SNR_snrPOI',[0 Inf] ,...
%     'trialfoc_enable',0,...
%     'trialfoc_focaltrialout','auto',...
%     'focalcomp_enable',1,...
%     'focalcomp_focalICAout','auto',...
%     'autocorr_enable',1,...
%     'autocorr_autocorrint',20,...
%     'autocorr_dropautocorr','auto',...
%     'opts_nocompute',0,...
%     'opts_FontSize',14, ...
%     'opts_noplot', 1);
% 
% fprintf('saving %s\n', fullfile(outpath, [name '_SAS.set']))
% EEG = pop_saveset( EEG, 'filename',[name,'_SAS.set'], 'filepath', outpath); %save final preprocessed output


EEG = pop_runica(EEG, 'extended',1,'interupt','on','PCA',30); 

%create file name
name = EEG.setname;
%name = EEG.filename(1:end-4);

name = [name, '_ICA'];

%change set name
fprintf('saving %s\n', fullfile(outpath, [name '.set']))
EEG = pop_editset(EEG, 'setname', name);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
EEG = pop_saveset(EEG, 'filename', [name '.set'], 'filepath', outpath);

end
