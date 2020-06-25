% function [] = selectDataforAnalysis(desiredTimes, ALLEEG)

%need continuous data for extraction 
EEG = ALLEEG(8);
j = 0;
ALLEEG2= struct();

EEG = pop_epoch2continuous(EEG);


for i = 1:length(desiredTimes)
    if (desiredTimes(i,1)) ~= 0
        
        j = j+1;
        startTime = newTimes(i,1);
        endTime = newTimes(i,2); 
        EEG_selectedData = pop_select( EEG,'time',[startTime endTime] ,'channel',{'Fp1' 'AF1' 'AF5' 'F7' 'F5' 'F3' 'F1' 'FC1' 'FC3' 'FC5' 'FT9' 'T7' 'C5' 'C3' 'C1' 'CP1' 'CP3' 'CP5' 'P9' 'P7' 'P5' 'P3' 'P1' 'PO3' 'PO7' 'PO9' 'O1' 'I1' 'Oz' 'POz' 'Pz' 'CPz' 'Fp2' 'AFz' 'AF2' 'AF6' 'F8' 'F6' 'F4' 'F2' 'Fz' 'FCz' 'FC2' 'FC4' 'FC6' 'FT10' 'T8' 'C6' 'C4' 'C2' 'Cz' 'CP2' 'CP4' 'CP6' 'P10' 'P8' 'P6' 'P4' 'P2' 'PO4' 'PO8' 'PO10' 'O2' 'I2' 'EX3' 'EX4' 'EX5'});
        EEG_selectedData = eeg_checkset( EEG_selectedData );

        [ALLEEG2, EEG_selectedData, CURRENTSET] = eeg_store( ALLEEG2, EEG_selectedData, j );

    end
end 

j = 1;
for i = 1:length(ALLEEG2)
    if ALLEEG2(i).xmax ~= 0 
        newALLEEG(j) = ALLEEG2(i);
        j= j+1;
        
    end
end

ALLEEG3 = ALLEEG;
ALLEEG = ALLEEG2;

for i = 1:length(ALLEEG)
    EEG = ALLEEG(i);
    EEG  = pop_editeventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99}, 'BoundaryString', { 'boundary' }, 'List',...
        '/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Prep/eventlist_afterSaccadeDetection.txt', 'SendEL2', 'EEG', 'UpdateEEG', 'askUser', 'Warning',...
        'on' );
    for j = 1:length(EEG.event)
        if isequal(EEG.event(j).type, 'MGSR')
            MGS_start = EEG.event(j).latency * .0066;
            saccade_start = EEG.event(j+1).latency * .0066;
            epochTime = (saccade_start - MGS_start) * 1000;
            EEG_epoch = pop_epochbin( EEG , [0.0  epochTime],  'none');
            ALLEEG4(i) = EEG_epoch;
        else
            continue;
            
        end
    end
    
end


%Merge all datasets into one

% ALL_EEG = pop_mergeset(newALLEEG, 1:length(newALLEEG), 1);
