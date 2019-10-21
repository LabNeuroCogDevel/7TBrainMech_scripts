function w_erps_freq_bands(condition_1,condition_2,frequency_bands,ERPS_path_to_files,alpha,color_cond_1,color_cond_2,color_alpha,stat_method)

if(~isdir(ERPS_path_to_files))
    error('Directory doesn''t exist');
    return;
end

files = dir(fullfile(ERPS_path_to_files,'*.mat'));
filenames = {files.name}';  
filenames=filenames{1:end-1};
file_nr = size(filenames,1);
all_tfX=[];
for s=1:file_nr
    load(filenames{s});
    all_tfX(:,:,:,:,s)=s_tfX;
    clear s_erps s_erpsboot s_tfX s_mbases
end

prefix_to_save=[condition_1 '_' condition_2];
P_1=squeeze(mean(all_tfX{1},5)); %average for all subjects, cond 1

P_2=squeeze(mean(all_tfX{2},5)); %average for all subjects, cond 2

for k=1:size(frequency_bands,1)
    freqs=frequency_bands(k,:);
    if freqs(1)<frequencies(1)
        freqs(1)=frequencies(1);
    end
    
    if freqs(2)>frequencies(length(frequencies))
        freqs(2)=frequencies(length(frequencies));
    end
   
    lower_index=interp1(frequencies,1:length(frequencies),freqs(1));
    upper_index=interp1(frequencies,1:length(frequencies),freqs(2));
    for ch=1:size(P_1,1)
        
        plot_collapsed_ERPS_by_subject(squeeze(P_1(ch,lower_index:upper_index,:,:)),squeeze(P_2(ch,lower_index:upper_index,:,:)),stat_method,alpha,prefix_to_save,[condition_1 '_' condition_2 num2str(freqs(1)) '_to_' num2str(freqs(2)) '_Hz',color_cond_1,color_cond_2,color_alpha);
     
    end
end
    