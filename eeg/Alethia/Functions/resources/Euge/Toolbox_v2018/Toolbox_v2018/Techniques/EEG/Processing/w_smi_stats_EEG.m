function [ EEG, data ] = w_smi_stats_EEG(filepath_to_save,taus, condition1, condition2, channel_nr, stat_method,alpha,EEG, data )
%Loads every .csd file (resulting from wSMI) in the directory specified by
%filepath_to_data, and for every specified tau calculates de average wSMI
%connectivity matrix

if isfield(data,'path_to_files')    
    filepath_to_data = data.path_to_files;
else 
    msgbox('Load path to data');
end;

%wSMI Tau pattern
tau_pattern = [1 2 4 8 16 32];

%load parameters
taus = str2num(taus);
channel_nr = str2num(channel_nr);
%channel_nr = EEG.nbchan;
alpha = str2num(alpha);

%load files
listing = dir(filepath_to_data);
dirFlags = [listing.isdir];
filenames = listing(~dirFlags);

for ti = 1: length(taus)
    tau = find(tau_pattern == taus(ti));
    disp(['wSMI Stats - Tau ' num2str(taus(ti))])
    C1_complete_mat = [];
    C2_complete_mat = [];
    C1_counter = 0;
    C2_counter = 0;

    for f = 1 : length(filenames)
        [fpath file_name fext] = fileparts(filenames(f).name);
        %TODO IMPROVE junk used to delete unwanted characters from file name due to
        %file name creation in wsmi scripts
        file_name = strrep(file_name,'_CSD','');
        filepath_to_data_mod = strrep(filepath_to_data,'\Results\SMI','');
        disp(['Processing ' filenames(f).name '....'])
        disp(file_name)
        %fileout= fullfile(filepath_to_data,'Results','SMI',[fileName,'_CSD.mat']);
        %the file name reveales whether it belongs to condition 1 or
        %condition 2 (ideally - see below)
        if strfind(file_name,condition1) > 0
            %file belongs to condition1
            disp(['File belongs to condition 1: ' condition1])                
            C1_counter = C1_counter + 1;
            C1 = load_wSMI_connectivity_matrix(filepath_to_data_mod,file_name,tau,channel_nr);
            C1_complete_mat(:,:,C1_counter) = mean(C1,3);
        elseif strfind(file_name, condition2) > 0
            disp(['File belongs to condition 2: ' condition2])
            C2_counter = C2_counter + 1;
            C2 = load_wSMI_connectivity_matrix(filepath_to_data_mod,file_name,tau,channel_nr);
            C2_complete_mat(:,:,C2_counter) = mean(C2,3);
        else
            disp([filenames(f).name ' is not either of ' condition1 ' nor ' condition2])            
        end
        
        %TODO - idealmente poder elegir entre condiciones de una matriz
        %mat = load_wSMI_connectivity_matrix(filepath_to_data,fileName,tau,channel_nr);
              %acá filtrar por condicion
        %[C1] = load_wSMI_connectivity_matrix(filepath_to_data,condition1,tau,channel_nr);
        %[C2] = load_wSMI_connectivity_matrix(filepath_to_data,condition2,tau,channel_nr);
    end
            
    mat = C1_complete_mat;
    
    file_to_save = fullfile(filepath_to_save,[condition1 '_tau' num2str(taus(ti)) '.mat']);
    save(file_to_save,'mat');
    disp(['Saved average wSMI matrix for condition 1 in ' file_to_save])
    clear mat
    
    mat = C2_complete_mat;
    file_to_save = fullfile(filepath_to_save,[condition2 '_tau' num2str(taus(ti)) '.mat']);
    save(file_to_save,'mat');
    disp(['Saved average wSMI matrix for condition 2 in ' file_to_save])
    clear mat
    
    disp(['Done creating average wSMI matrices for conditions ' condition1 ' and ' condition2 '.'])
    
    %calculate statistics between condition 1 and condition 2
    disp('Performing statistical comparison')
    [tsignificant,t,p] = connectivity_stats(C1_complete_mat,C2_complete_mat,stat_method,alpha);
    file_to_save = fullfile(filepath_to_save,[condition1 '_' condition2 '_tau' num2str(taus(ti)) '_' stat_method '_' num2str(alpha) '.mat']);
    save(file_to_save,'tsignificant','t','p')
    disp(['Saved statistical comparison in file ' file_to_save])
end
return
        