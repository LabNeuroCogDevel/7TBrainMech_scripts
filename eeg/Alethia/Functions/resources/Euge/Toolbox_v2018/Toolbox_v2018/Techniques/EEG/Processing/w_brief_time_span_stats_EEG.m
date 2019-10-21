function [ EEG, data ] = w_brief_time_span_stats_EEG(filepath_to_save, condition1, condition2, bandpass_ranges, time_ranges,stat_method,alpha,EEG, data )
%Loads every .mat file (resulting from brief_time_span) in the directory specified by
%filepath_to_data\BTS, and for every frequency and time range calculates de
%average 
%connectivity matrix


%load parameters
bandpass_ranges = str2num(bandpass_ranges);
time_ranges = str2num(time_ranges);
alpha = str2num(alpha);

filepath_to_data=data.path_to_files{1};

for fi = 1: size(bandpass_ranges,1)
    low_freq = bandpass_ranges(fi,1);
    high_freq = bandpass_ranges(fi,2);
    disp(['Brief Time Span Stats - Frequency range:  ' num2str(low_freq) '-' num2str(high_freq)])
    
    for ti = 1  : size(time_ranges,1)
               
        t1 = time_ranges(ti,1);
        t2 = time_ranges(ti,2);
    
        C1_complete_mat = [];
        C2_complete_mat = [];
        C1_counter = 0;
        C2_counter = 0;
        
        %load files
        filepath_to_data_mod = fullfile(filepath_to_data,[num2str(f1) '-' num2str(f2)],[num2str(t1) '_' num2str(t2)]);
        files = dir(fullfile(filepath_to_data_mod,'*.mat'));
        filenames = {files.name}';  
        file_nr = size(filenames,1);

        for f = 1 : file_nr
            [fpath file_name fext] = fileparts(filenames(f).name);
            %TODO - idealmente poder elegir entre condiciones
            %de una matriz                       
            disp(['Processing ' filenames(f).name '....'])
            disp(file_name)
            %the file name reveales whether it belongs to condition 1 or
            %condition 2 (ideally - see below)
            
            filename_parts = strsplit(file_name,'_');
            file_condition = filename_parts(1);
            if strcmp(file_condition,condition1) > 0
                %file belongs to condition1
                disp(['File belongs to condition 1: ' condition1])                
                C1_counter = C1_counter + 1;
                C1 = load(fullfile(filepath_to_data_mod,filenames(f).name)); 
                C1_complete_mat(:,:,C1_counter) = mean(C1,3);
            elseif strfind(file_name, condition2) > 0
                disp(['File belongs to condition 2: ' condition2])
                C2_counter = C2_counter + 1;
                C2 = load(fullfile(filepath_to_data_mod,filenames(f).name)); 
                C2_complete_mat(:,:,C2_counter) = mean(C2,3);
            else
                disp([filenames(f).name ' is not either of ' condition1 ' nor ' condition2])            
            end


        end   
        mat = C1_complete_mat;
        file_to_save = fullfile(filepath_to_save,[condition1 '_f' num2str(low_freq) '_' num2str(high_freq) '_t' num2str(t1) '-' num2str(t2) '.mat']);
        save(file_to_save,'mat');
        disp(['Saved average wSMI matrix for condition 1 in ' file_to_save])
        clear mat

        mat = C2_complete_mat;
        file_to_save = fullfile(filepath_to_save,[condition2 '_f' num2str(low_freq) '_' num2str(high_freq) '_t' num2str(t1) '-' num2str(t2) '.mat']);
        save(file_to_save,'mat');
        disp(['Saved average wSMI matrix for condition 2 in ' file_to_save])
        clear mat

        disp(['Done creating average wSMI matrices for conditions ' condition1 ' and ' condition2 '.'])
        
        %calculate statistics between condition 1 and condition 2
        disp('Performing statistical comparison')
        [t,p] = connectivity_stats(C1_complete_mat,C2_complete_mat,stat_method,alpha);
        file_to_save = fullfile(filepath_to_save,[condition1 '_' condition2 '_f' num2str(low_freq) '_' num2str(high_freq) '_t' num2str(t1) '-' num2str(t2) '.mat']);
        save(file_to_save,'t','p')
        disp(['Saved statistical comparison in file ' file_to_save])
    end
end
return
        