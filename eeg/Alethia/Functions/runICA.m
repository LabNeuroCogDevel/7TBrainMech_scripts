function [] = runICAss(inpath,)
%% this script runs ICA on all filtered/cleaned/epoched EEG dmt data.
% PCA is used to decrease the number of components 

%% run ICA
EEGfileNames = dir([inpath, '*.set']);

eeglab
for currentEEG = 1:size(EEGfileNames,1)
    
    %load data
    EEG = pop_loadset('filename',EEGfileNames(currentEEG).name,...
        'filepath',fileparts(inpath));
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    
    disp(EEGfileNames(currentEEG).name);
    
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
    all_ch = 1:64;
    badchans = channels_removed{3,1}; 
    all_ch(badchans) = [];%canales que van para ICA

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
    
end