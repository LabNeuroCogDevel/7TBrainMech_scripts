function w_plot_ersp_freq_bands_EEG(condition_1,condition_2,erps_files_prefix,frequency_bands,ERPS_files_path,alpha,color_cond_1,color_cond_2,color_alpha,stat_method,path_to_save)

load(ERPS_files_path);

P_1=mean(erps{1},4); %average for all subjects, cond 2
P_1=mean(P_1,4);
P_2=mean(erps{2},4); %average for all subjects, cond 2

for k=1:length(frequency_bands)
    frequencies=str2num(frequencu_bands(k));
    if frequencies(1)<freqs(1)
        lower_freq=freqs(1);
    else
        lower_freq=interp1(freqs,1:length(freqs),frequencies(1));
    end
    
    if frequencies(2)<freqs(length(freqs))
        upper_freq=freqs(length(freqs));
    else
        upper_freq=interp1(freqs,1:length(freqs),frequencies(2));
    end
   
    ERPS_band_cond_1=P_1(:,lower_freq:upper_freq,:);
    mean_ERPS_c1=mean(ERPS_band_cond_1,2);
    
    ERPS_band_cond_2=P_2(:,lower_freq:upper_freq,:);
    mean_ERPS_c2=mean(ERPS_band_cond_2,2);
    
    hdl=plot(timesout,mean_ERPS_c1,color_cond_1,timesout,mean_ERPS_c2,color_cond_2);
    legend(condition_1,condition_2);
    title(strcat('Mean value of ERPS for both conditions for frequencies between',num2str(lower_freq),'Hz and',num2str(upper_freq),'Hz'));
    
    file_name_to_save=strcat('freqs_',num2str(lower_freq),'_to_',num2str(upper_freq));
    plot_name = fullfile(path_to_save,[file_name_to_save '.tif']);        
    print(hdl,plot_name,'-dtiff','-r0');
    
    close(hdl);
end