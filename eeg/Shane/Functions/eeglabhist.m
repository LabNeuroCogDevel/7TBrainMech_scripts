% EEGLAB history file generated on the 08-Mar-2022
% ------------------------------------------------
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename','10129_20180919_ss_Rem_rerefwhole_ICA_icapru.set','filepath','H:\\Projects\\7TBrainMech\\scripts\\eeg\\Shane\\AudSteadyState\\AfterWhole\\ICAwholeClean_homogenize\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
EEG = eeg_checkset( EEG );
EEG = pop_rmdat( EEG, {'4'},[-1 1] ,0);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
EEG = eeg_checkset( EEG );
pop_eegplot( EEG, 1, 1, 1);
EEG = eeg_checkset( EEG );
figure; pop_newtimef( EEG, 1, 1, [0  161160], [3         0.5] , 'topovec', 1, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', 'Fp1', 'baseline',[0], 'plotphase', 'off', 'padratio', 1);
EEG = eeg_checkset( EEG );
EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' } ); % GUI: 08-Mar-2022 15:41:36
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off'); 
EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' }, 'Eventlist', 'H:\Projects\7TBrainMech\scripts\eeg\Shane\eventList.txt' ); % GUI: 08-Mar-2022 15:43:54
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'gui','off'); 
eeglab redraw;
