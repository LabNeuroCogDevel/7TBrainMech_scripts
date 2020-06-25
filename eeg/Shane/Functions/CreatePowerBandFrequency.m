load('/Projects/7TBrainMech/scripts/eeg/Alethia/Results/TF/test/10129_20180919_mgs_Rem_rerefwhole_ICA_icapru_epochs_rj_4.mat')

[locs] = find(freqs > 30);
[timeLocs] = find(timesout > 0); 

imagesc(squeeze(s_erps(1,:,:)))
roi = [31 59 58];
powerBand = [];
for j = 1:length(freqs)
    for i = 1:length(roi)
        powerBand(i,j) = mean(squeeze(s_erps(roi(i),j,timeLocs))); 
    end
end
avgPB = mean(powerBand);
plot(freqs, avgPB); 

loglog(freqs, avgPB); 

