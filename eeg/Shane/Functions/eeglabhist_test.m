% EEGLAB history file generated on the 22-Sep-2022
% ------------------------------------------------

EEG.etc.eeglabvers = '2022.1'; % this tracks which version of EEGLAB is being used, you may ignore it
EEG = eeg_checkset( EEG );
EEG.setname='10202_20210714_ss_Rem';
EEG = eeg_checkset( EEG );
EEG = eeg_checkset( EEG );
EEG = eeg_checkset( EEG );
EEG = eeg_checkset( EEG );
EEG = eeg_checkset( EEG );
EEG=pop_chanedit(EEG, 'lookup','H:\\Projects\\7TBrainMech\\scripts\\eeg\\Shane\\Functions\\resources\\eeglab2022.1\\plugins\\dipfit2.3\\standard_BESA\\standard-10-5-cap385.elp');
EEG = eeg_checkset( EEG );
figure; topoplot([],EEG.chanlocs, 'style', 'blank',  'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);
pop_eegplot( EEG, 1, 1, 1);
