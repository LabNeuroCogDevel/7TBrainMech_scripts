function [] = runICAss(inpath, schans, outpath, varargin)
%% this script runs ICA on all filtered/cleaned/epoched EEG dmt data.
% PCA is used to decrease the number of components 
% varargin can contain 'redo' to ignore file already done


%% find file
% if no file, try searching with *.set
if exist(inpath,'file')
   EEGfileNames=dir(inpath)
else
   EEGfileNames = dir([inpath, '*.set']);
end
currentEEG = EEGfileNames.name;

% did we already run?
finalout = fullfile(outpath, [name '_SAS.set'])
if exist(finalout, 'file') && ~isempty(strmatch('redo', varargin)))
   warning('already created %s, not running. add "redo" to ICA call to redo', finalout)
   return
end

%% run ICA
eeglab

%load data
EEG = pop_loadset('filename',currentEEG, 'filepath', fileparts(inpath));
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

disp(currentEEG);

%control for rank defficiency: if you want to analyse components as
%(and not only use the components to remove noise) you should keep the
%nr of components contstant across datasets. But there should not be
%more components than channels. (So check how many channels are removed).

%     PCAnr = 15; %for example 10 components because in 1 dataset 14 channels were removed
%     %PCAnr = EEG.nbchan - EEG.channels_rj_nr; %or if you are not interested
%     %in component analysis but want to use ICA only for artifact removal
%     %change the PCAnr for each dataset individually
%
%     %[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
%     EEG = pop_runica(EEG, 'extended',1,'interupt','on','PCA',PCAnr);
% run ICA
if(size(EEG.data,1)<100)
    all_ch = 1:64;
    badchans = schans{3,1};
    all_ch(badchans) = [];%canales que van para ICA
else
    all_ch = 1:128;
    badchans = schans{3,1};
    all_ch(badchans) = [];%canales que van para ICA
end


EEG = pop_runica(EEG, 'extended',1,'interupt','on','chanind',all_ch);    
%create file name
name = EEG.setname;
%name = EEG.filename(1:end-4);

name = [name, '_ICA'];

%change set name
EEG = pop_editset(EEG,...
    'setname',name);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%save set
EEG = pop_saveset( EEG, 'filename',[name,'.set'],'filepath',outpath);

%% SASICA Command

%Then the user would pull up ICA'd results, and run SAS:
EEG = eeg_SASICA(EEG,'MARA_enable',0,'FASTER_enable',0,'FASTER_blinkchanname','EX5','ADJUST_enable',0,'chancorr_enable',1,'chancorr_channames','No channel','chancorr_corthresh','auto 4','EOGcorr_enable',0,'EOGcorr_Heogchannames','No channel','EOGcorr_corthreshH','auto 4','EOGcorr_Veogchannames','No channel','EOGcorr_corthreshV','auto 4','resvar_enable',0,'resvar_thresh',15,'SNR_enable',1,'SNR_snrcut',1,'SNR_snrBL',[-Inf 0] ,'SNR_snrPOI',[0 Inf] ,'trialfoc_enable',0,'trialfoc_focaltrialout','auto','focalcomp_enable',1,'focalcomp_focalICAout','auto','autocorr_enable',1,'autocorr_autocorrint',20,'autocorr_dropautocorr','auto','opts_noplot',0,'opts_nocompute',0,'opts_FontSize',14);
EEG = pop_saveset( EEG, 'filename',[name,'_SAS'],'filepath',outpath); %save final preprocessed output

end
