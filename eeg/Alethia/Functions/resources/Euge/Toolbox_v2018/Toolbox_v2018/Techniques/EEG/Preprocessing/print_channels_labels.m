function [EEG, data] = print_channels_labels(titleName, EEG, data)

channelNr = size(EEG.data,1);
channelList{channelNr} = '';

fileID = fopen([data.path titleName '_ChannelLabels.txt'],'w');
formatSpec = '%d %s\r\n';

for i = 1 : channelNr
    channelList{i} = EEG.chanlocs(i).labels;    
    fprintf(fileID,formatSpec,i,EEG.chanlocs(i).labels);
end

fclose(fileID);

labels = channelList;

titleNameMat = [data.path titleName '.mat'];

save(titleNameMat,'labels'); %Modificación para admitir espacios en el path (19/3/18).
