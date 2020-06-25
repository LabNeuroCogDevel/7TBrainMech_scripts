function [] = Evaluate_HEOG()

%open eeglab
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

%load in file
EEG = pop_loadset('filename','10129_20180919_mgs_Rem.set','filepath','/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Prep/remarked/');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
EEG = eeg_checkset( EEG );


%resampled (150 hz)
EEG = pop_resample( EEG, 150);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 


%filter, low: 0.05 Hz, high:74 Hz
EEG = pop_eegfiltnew(EEG, 0.05,[],9900,0,[],1);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname','10129_20180919_mgsRem resampled_filter','gui','off'); 
EEG = eeg_checkset( EEG );


%rereference to channels 65 and 66
EEG = pop_reref( EEG, [65 66] );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'setname','10129_20180919_mgsRem resampled_filter_reref','gui','off'); 
EEG = eeg_checkset( EEG );


%delete external channels
EEG = pop_select( EEG,'nochannel',{'EX6' 'EX7' 'EX8'});
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'setname','10129_20180919_mgsRem resampled_filter_reref_chanRemoved','gui','off'); 
eeglab redraw;
EEG = eeg_checkset( EEG );


%import eventlist
EEG = pop_importeegeventlist( EEG, '/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Prep/eventlist.txt' , 'ReplaceEventList', 'on' ); % GUI: 11-Nov-2019 10:04:48
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 5,'gui','off'); 


%epoch based off event list
EEG = pop_epochbin( EEG , [0.0  2000.0],  'none'); % GUI: 11-Nov-2019 10:06:41
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 6,'setname','10129_20180919_mgsRem resampled_filter_reref_chanRemoved_impel_epoched','gui','off'); 
EEG = eeg_checkset( EEG );


%create HEOG channel 
EEG = pop_eegchanoperator( EEG, {  'ch68 =ch65 - ch66 label HEOG'} , 'ErrorMsg', 'popup', 'Warning', 'on' ); % GUI: 11-Nov-2019 10:09:26
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
eeglab redraw;

EEG = eeg_checkset(EEG,'makeur','checkur');

EEG = pop_detecteyemovements(EEG,[65 67] ,[66 67] ,6,4,[],1,0,8,1,1,1,1);

for i = 1:length(EEG.event)
    
    if isequal(EEG.event(i).type, 'saccade') || isequal(EEG.event(i).type, 'fixation')
        EEG.event(i).binlabel = EEG.event(i-1).binlabel;
        
    
    else
        continue;
    end
    
end

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 8,'setname','10129_20180919_mgsRem resampled_filter_reref_chanRemoved_impel_epoched_saccades','gui','off'); 


%take one second after mgs onset before saccade
for i = 1:length(EEG.event)
    
    if isequal(EEG.event(i).type, 'B5(5)') && isequal(EEG.event(i).binlabel, 'B5(5)')
       Epoch_latency = EEG.event(i+1).latency; 
       Saccade_onset_latency = EEG.event(i+2).latency;
       
       Epoch_timeStamp = Epoch_latency * .0066;
       Saccade_onset_timeStamp = Saccade_onset_latency * .0066;
       
       desiredTimes(i,:) = [Epoch_timeStamp Saccade_onset_timeStamp];
       
       desiredLatency(i,:) = [Epoch_latency Saccade_onset_latency];
       

    else
        continue;
    end
    
end

newTimes(:,1) = floor(desiredTimes(:,1));
newTimes(:,2) = ceil(desiredTimes(:,2));
 

%Extract data based on the time points we want to analyze 
[] = selectDataforAnalysis(desiredTimes, ALLEEG);
