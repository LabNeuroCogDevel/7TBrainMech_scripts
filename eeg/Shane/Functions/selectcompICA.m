% dont run as a function, it needs access to EEG in workspace
%function [OUTEEG] = selectcompICA(path_data,filename,CleanICApath)
% 

% quick check that path_data is valid
if ~ exist(path_data,'dir'); error('no path_data directory "%s"!', path_data); end

% locs = file_locs(fullfile(path_data,filename));
% if exist(locs.ICAwholeClean, 'file')
%     OUTEEG = [];
%     fprintf('skipping; already created %s\n', locs.ICAwholeClean);
%     %OUTEEG = pop_loadset(locs.ICAwholeClean);
%     return
% end
% % 
% %% must have ica comps.
% % if already run this will return out without doing anything
% runICAs(locs.rerefwhole_name, hera('Projects/7TBrainMech/scripts/eeg/Shane/Prep/ICAwhole'))


% prefix ='_prep_allepoch_ica.set'
EEG = pop_loadset('filename',filename,'filepath',path_data);
% EEG.setname = ['UG_' suj_n, '_',prefix(1:end-4)];
EEG = eeg_checkset( EEG );

% DB point on 28
[EEG, com] = pop_selectcomps(EEG, [1:30] );
pop_eegplot(EEG, 0, 1, 1);
pop_saveset( EEG, 'filename',[filename(1:end-4),'_pesos.set'],'filepath',CleanICApath);
% pop_eegplot( EEG, 0, 1, 1);
eeglab redraw
lowBP
% TEXTO = 'Lista la sel de comp? (If not put [0])';
% interp_user_def = input(TEXTO);
% 
% if interp_user_def~= 0
cmps = find(EEG.reject.gcompreject);
eeglab redraw
OUTEEG = pop_subcomp( EEG, [cmps], 1);
eeglab redraw
pop_saveset( OUTEEG, 'filename',[filename(1:end-4),'_icapru.set'],'filepath',CleanICApath);
% end
close all
