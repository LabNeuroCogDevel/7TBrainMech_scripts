restoredefaultpath
addpath('Functions')
addpath(genpath('Functions/resources/Euge/Toolbox_v2018'))

% Functions/resources/Euge/Toolbox_v2018/Toolbox_v2018/Toolbox.m
% Toolbox
% EEG; File -> path to data -> 
% /Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/epochcleanTF
% imagesc(squeeze(s_erps{2}(1,:,:)))
files = dir(hera('/Projects/7TBrainMech/scripts/eeg/Alethia/Results/TF/Delay_Period_Data/*.mat')),
PSD = zeros(length(files), 60);

for i = 1: length(files)
    disp(i)

    subject = files(i).name;
    filename = hera(sprintf('/Projects/7TBrainMech/scripts/eeg/Alethia/Results/TF/Delay_Period_Data/%s', subject));
    load(filename)
    
    timebins = find(timesout>0);
    freqbins= find(freqs>30);
    channel = [32 23 59 31 24 60 58];
    
    PSD_i = zeros(1,60);
    
    for j = 1:length(freqs)
        PSD_i(j) = calcPSD( s_erps,timebins,j,channel, s_mbases );
    end
    
    PSD(i,:) = PSD_i; 
%     plot(freqs, PSD_i);
    
end



save('PSD.mat', 'PSD'); 

gammaAnalysis(PSD, freqs, files);




