% EEGLAB history file generated on the 01-Jul-2022
% ------------------------------------------------
EEG = pop_loadset('filename','10129_20180919_ss_Rem_rerefwhole_ICA_icapru.set','filepath','H:\\Projects\\7TBrainMech\\scripts\\eeg\\Shane\\AudSteadyState\\AfterWhole\\ICAwholeClean_homogenize\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
EEG = eeg_checkset( EEG );
pop_eegplot( EEG, 1, 1, 1);
EEG = eeg_checkset( EEG );
EEG = pop_epoch( EEG, {  '4'  }, [-0.2           1], 'newname', '10129_20180919_ss_Rem_rerefwhole_ICA pruned with ICA epochs', 'epochinfo', 'yes');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off'); 
EEG = eeg_checkset( EEG );
EEG = pop_rmbase( EEG, [-200    0]);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'gui','off'); 
EEG = eeg_checkset( EEG );
pop_eegplot( EEG, 1, 1, 1);
EEG = eeg_checkset( EEG );
figure; pop_newtimef( EEG, 1, 6, [-200  993], [7         0.5] , 'topovec', 6, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', 'F3', 'baseline',[0], 'freqs', [30 75], 'plotphase', 'off', 'ntimesout', 400, 'padratio', 1);
EEG = eeg_checkset( EEG );
figure; pop_newtimef( EEG, 1, 6, [-200  993], [0] , 'topovec', 6, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', 'F3', 'baseline',[NaN], 'freqs', [30 75], 'plotphase', 'off', 'scale', 'abs', 'ntimesout', 150, 'padratio', 1);
EEG = eeg_checkset( EEG );
figure; pop_newtimef( EEG, 1, 6, [-200  993], [0] , 'topovec', 6, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', 'F3', 'baseline',[0], 'freqs', [5 55], 'plotphase', 'off', 'ntimesout', 400, 'padratio', 1);
EEG = eeg_checkset( EEG );
figure; pop_newtimef( EEG, 1, 6, [-200  993], [7         0.5] , 'topovec', 6, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', 'F3', 'baseline',[0], 'freqs', [30 75], 'plotphase', 'off', 'padratio', 1);
eeglab redraw;
