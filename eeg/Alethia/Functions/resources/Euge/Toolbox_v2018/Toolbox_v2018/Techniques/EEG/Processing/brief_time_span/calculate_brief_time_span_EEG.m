function calculate_brief_time_span_EEG(EEG,condition_1, condition_2,bandpass_ranges,epoch_window,base_window,time_ranges,path_to_save)                                                                                 
%Calculates brief time span connectivity for two conditions. This method
%filters the iEEG signal in a desired frequency range. Then the correlation coefficient is calculated.

%INPUTS:
%EEG: Full EEG, not epoched to filter

%condition_1: name of condition_1 (must be a cell array)
%condition_2: name of condition_2 (must be a cell array)
%bandpassRange: a two value vector with the frequency range to be filtered,
%               e.g. bandpassRange = [minfreq maxfreq];
%epoch_window: vector of two values used to determine epoch window
%base_window: vector of two values used to determine base window 

%filter EEG signal in desired frequency range

%TODO replace for a better filtering function

for f = 1 : size(bandpass_ranges,1)
    f_EEG = EEG;
    bandpass_range = bandpass_ranges(f,:);
    low_freq =  bandpass_range(1,1);
    high_freq =  bandpass_range(1,2);
    f_EEG = pop_eegfiltnew(f_EEG, low_freq,high_freq, 1690, 0, [], 0);
    
    %epoch signal
    %NO SE PARA QUE ES ESTO!?!?!
    types = unique({EEG.event.type});
    str = '';
    for i=1:length(types)
        if isequal(str,'')
            str = types{i};
        else
            str = [str ' ' types{i}];
        end
    end
    types = strsplit(str);

    [e_EEG ] = ieeg_epoch(types, epoch_window, base_window,'', f_EEG);

    %filter by conditions
    EEG_condition_1 = filter_epochs(strsplit(condition_1), e_EEG);
    EEG_condition_2 = filter_epochs(strsplit(condition_2), e_EEG);
    
    %calculo correlacion 
    channel_nr = size(signal1,1);
    
    for t = 1 : size(time_ranges,1)
        
        time_range = time_ranges(t,:);
        
        t1 = round(interp1(EEG_condition_1.times,1:length(EEG_condition_1.times),time_range(1)));
        t2 = round(interp1(EEG_condition_2.times,1:length(EEG_condition_2.times),time_range(2)));
        
        signal1 = EEG_condition_1.data(t1:t2,:,:);
        signal2 = EEG_condition_2.data(t1:t2,:,:);

        cond1_trial_nr = size(signal1,3);
        correlation_cond1 = zeros(channel_nr,channel_nr,cond1_trial_nr);

        for i = 1 : cond1_trial_nr
            [R1,P,RLO,RUP] = corrcoef(signal1(:,:,i)');
            correlation_cond1(:,:,i) = R1;
        end

        cond2_trial_nr = size(signal2,3);
        correlation_cond2 = zeros(channel_nr,channel_nr,cond2_trial_nr);

        for j = 1 : cond2TrialNr
            [R2,P,RLO,RUP]=corrcoef(signal2(:,:,j)');
            correlation_cond2(:,:,j) = R2;
        end
                
        %creates a subfolder to save results for each frequency range
        path_to_save_mats = fullfile(path_to_save, [num2str(low_freq) '_' num2str(high_freq)],[num2str(t1) '_' num2str(t2)]);

        if ~exist(path_to_save_mats, 'dir')
          mkdir(path_to_save_mats);
        end 
        
        mat = correlation_cond1;
        file_to_save = fullfile(path_to_save_mats,[condition1 '_f' num2str(low_freq) '-' num2str(high_freq) '_t' num2str(t1) '-' num2str(t2) '.mat']);
        save(file_to_save,'mat');
        disp(['Saved average correlation matrix for condition 1 in ' file_to_save])
        clear mat
        
        mat = correlation_cond2;
        file_to_save = fullfile(path_to_save_mats,[condition2 '_f' num2str(low_freq) '-' num2str(high_freq) '_t' num2str(t1) '-' num2str(t2) '.mat']);
        save(file_to_save,'mat');
        disp(['Saved average correlation matrix for condition 2 in ' file_to_save])
        clear mat
    end
end