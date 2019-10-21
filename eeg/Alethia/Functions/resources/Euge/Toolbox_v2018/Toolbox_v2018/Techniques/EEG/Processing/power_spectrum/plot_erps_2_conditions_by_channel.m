function plot_erps_2_conditions_by_channel(file_name,sample_EEG,path_to_save,prefix_file_name_to_save)
%plots time frequency charts for 2 conditions 
%INPUTS:
% file_name: name of .mat file with w2_erps_2_conditions_by_channel_EEG
%           results
% sample_EEG: EEG with useful channel location and labels
% path_to_save


load(file_name)
%loads the results of w2_erps_2_conditions_by_channel_EEG for all sujs
%with the following variables
%erps = {c1_erps,c2_erps,c1_c2_erps};
%erpsboot = {c1_erpsboot,c2_erpsboot,c1_c2_erpsboot};
%all_tfX = {c1_alltfX,c2_alltfX};
%mbases = {c1_mbases,c2_mbases};
%timesout
%freqs
%g

%calculate mean erps for all subjects, and mean baseline
mean_base1 = mean(mbases{1},3);
mean_base2 = mean(mbases{2},3);
mean_P1 = mean(erps{1},4);
mean_P2 = mean(erps{2},4);
mean_P1_2 = mean(erps{3},4);
mean_base = {mean_base1,mean_base2};
P_all = {mean_P1, mean_P2,mean_P1_2};   %mean ERPS entre todos los sujetos  

%plot------------------------------
for ch = 1 : sample_EEG.nbchan
    disp(['About to plot ch' num2str(ch)])
    chanlabel = EEG.chanlocs(ch).labels; 
    P_to_plot = {squeeze(P_all{1}(ch,:,:)),squeeze(P_all{2}(ch,:,:)),squeeze(P_all{3}(ch,:,:))};
    mbase_to_plot = {squeeze(mean_base{1}(ch,:,:)) squeeze(mean_base{2}(ch,:,:))};
    g.topovec = ch; %index del valor a plotear
    
    plot_erps_2_conditions_tiff(P_to_plot,mbase_to_plot,g,freqs,timesout,path_to_save,[chanlabel '_' prefix_file_name_to_save],all_tfX);

end