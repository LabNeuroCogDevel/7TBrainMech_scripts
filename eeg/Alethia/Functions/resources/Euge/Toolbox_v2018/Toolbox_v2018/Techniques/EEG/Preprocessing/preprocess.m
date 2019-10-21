function [EEG, data] = preprocess(labelFileName,channels2Delete,notchHz,notchWidth,bandpassRange,filteredFileName,referencedFileName, EEG, data)

%preprocesses fileName.set at filePath -> e.g. 'C:\\Documents\\Sets\\'
%this includes opening eeglab to load the .set
%prints a file labelFileName__ChannelLabels.txt
%removes channels included in channels2Delete (for being noisy, for not being relevant, etc...
%prints a file labelFileName__PreprocessedChannelLabels.txt without the
%deleted channels of the previous step
%Notch Filter at each notchHz in array with a width of notchWidth
%Band-pass filter -> bandpassRange = [min max]
%re-referencing to the mean average of the signal


%remove bad channels
EEG = discard_channels(channels2Delete, EEG);
% eeglab redraw

%print channel labels
print_channels_labels([labelFileName '_Preprocessed'], EEG, data);

%plot power spectrum one channel pre-Notch filtering 
plot_power_spectrum(EEG.data(1,:),EEG.srate,'Signal without Notch filtering')

%Notch filter
for i = 1 : size(notchHz,2)
    EEG.data = notch_filter(EEG, notchHz(1,i),notchWidth);
end

%Band-pass filtering
figure
EEG = pop_eegfiltnew(EEG, bandpassRange(1,1), bandpassRange(1,2), 3380, 0, [], 1);

plot_power_spectrum(EEG.data(1,:),EEG.srate,'Band-pass filtered Signal')

filteredData = EEG.data;
%save 'filteredData.mat' filteredData
evalStr = ['save ' fullfile(data.path, [ filteredFileName '.mat']) ' filteredData'];
save(fullfile(data.path, [ filteredFileName '.mat']),'filteredData'); %Modificación 23/3
%eval(evalStr);

%referencia a la media
avg = mean(filteredData,1);
avgMatrix = repmat(avg,size(filteredData,1),1);
mean_data = filteredData - avgMatrix;

%save 'data.mat' data;
evalStr = ['save ' fullfile(data.path, [referencedFileName '.mat']) ' mean_data'];
save(fullfile(data.path, [referencedFileName '.mat']),'mean_data'); %modificación 23/3
%eval(evalStr);
