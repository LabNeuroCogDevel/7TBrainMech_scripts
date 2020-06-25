

addpath('H:Projects/7TBrainMech/scripts/eeg/toolbox/SpectralEvents-master')

addpath(genpath('Functions'));
addpath(hera('/Projects/7TBrainMech/scripts/fieldtrip-20191127'))
ft_defaults

datapath = hera('/Projects/7TBrainMech/scripts/eeg/Shane/Prep/AfterWhole/ICAwholeClean_homogenize');

%load in all the delay files
setfiles0 = dir([datapath,'/*icapru.set']);
setfiles = {};

for epo = 1:length(setfiles0)
    setfiles{epo,1} = fullfile(datapath, setfiles0(epo).name); % cell array with EEG file names
    % setfiles = arrayfun(@(x) fullfile(folder, x.name), setfiles(~[setfiles.isdir]),folder, 'Uni',0); % cell array with EEG file names
end



% Avg Power
for j = 1 : length(setfiles0)

    idvalues(j,:) = (setfiles0(j).name(1:14));
end

IDtoPower = table(idvalues, AvgPower'); 
IDtoPower = IDtoPower(IDtoPower.Var2(:,1) ~= 0, :);

AvgPower( :, all(~AvgPower,1) ) = [];
distances = (pdist(AvgPower', 'euclidean'));
dissimilarities = squareform(distances); 

clear colAvg
clear subAvg
for i = 1: length(dissimilarities)
    colAvg(i, :) = sum(dissimilarities(:,i)) ./ sum(dissimilarities~=0, 1);
    subAvg(i,:) = mean(colAvg(i,:)); 
end

OverallDistance = mean(subAvg); 
OverallSD = std(subAvg); 
Z = (subAvg - OverallDistance)/OverallSD; 

include = find(Z < 3); 
exclude = find(Z > 3); %  THESE ARE THE SUBJECTS YOU NEED TO DROP

subjectID_exclude = IDtoPower(exclude, :);
subjectID_include = IDtoPower(include,:);

disp(subjectID_exclude.idvalues); 

newAvgPower = AvgPower(:, include); 
newDistances = pdist(newAvgPower', 'euclidean'); 
NewDissimilarities = squareform(newDistances);

[Y] = cmdscale(NewDissimilarities,2);
plot(Y(:,1), Y(:,2), '.'); 

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/GammaaAvgPower_NoOutliers.mat'), 'subjectID_include')




% Peak Power
for j = 1 : length(setfiles0)

    idvalues(j,:) = (setfiles0(j).name(1:14));
end

IDtoPower = table(idvalues, peakPower'); 
IDtoPower = IDtoPower(IDtoPower.Var2(:,1) ~= 0, :);

peakPower( :, all(~peakPower,1) ) = [];
distances = (pdist(peakPower', 'euclidean'));
dissimilarities = squareform(distances); 

clear colAvg
clear subAvg
for i = 1: length(dissimilarities)
    colAvg(i, :) = sum(dissimilarities(:,i)) ./ sum(dissimilarities~=0, 1);
    subAvg(i,:) = mean(colAvg(i,:)); 
end

OverallDistance = mean(subAvg); 
OverallSD = std(subAvg); 
Z = (subAvg - OverallDistance)/OverallSD; 

include = find(Z < 3); 
exclude = find(Z > 3); %  THESE ARE THE SUBJECTS YOU NEED TO DROP

subjectID_exclude = IDtoPower(exclude, :);
subjectID_include = IDtoPower(include,:);
disp(subjectID_exclude.idvalues); 

newPower = peakPower(:, include); 
newDistances = pdist(newPower', 'euclidean'); 
NewDissimilarities = squareform(newDistances);

[Y] = cmdscale(NewDissimilarities,2);
plot(Y(:,1), Y(:,2), '.'); 

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/ThetaPeakPower_NoOutliers.mat'), 'subjectID_include')



% Number of events 
for j = 1 : length(setfiles0)

    idvalues(j,:) = (setfiles0(j).name(1:14));
end

IDtoPower = table(idvalues, AvgEventNumber'); 
IDtoPower = IDtoPower(IDtoPower.Var2(:,1) ~= 0, :);

AvgEventNumber( :, all(~AvgEventNumber,1) ) = [];
distances = (pdist(AvgEventNumber', 'euclidean'));
dissimilarities = squareform(distances); 

clear colAvg
clear subAvg
for i = 1: length(dissimilarities)
    colAvg(i, :) = sum(dissimilarities(:,i)) ./ sum(dissimilarities~=0, 1);
    subAvg(i,:) = mean(colAvg(i,:)); 
end

OverallDistance = mean(subAvg); 
OverallSD = std(subAvg); 
Z = (subAvg - OverallDistance)/OverallSD; 

include = find(Z < 3); 
exclude = find(Z > 3); %  THESE ARE THE SUBJECTS YOU NEED TO DROP

subjectID_exclude = IDtoPower(exclude, :);
subjectID_include = IDtoPower(include,:);
disp(subjectID_exclude.idvalues); 

newPower = AvgEventNumber(:, include); 
newDistances = pdist(newPower', 'euclidean'); 
NewDissimilarities = squareform(newDistances);

[Y] = cmdscale(NewDissimilarities,2);
plot(Y(:,1), Y(:,2), '.'); 

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/BetaNumberofEvents_NoOutliers.mat'), 'subjectID_include')


% Duration of events 
for j = 1 : length(setfiles0)

    idvalues(j,:) = (setfiles0(j).name(1:14));
end

IDtoPower = table(idvalues, AvgEventDuration'); 
IDtoPower = IDtoPower(IDtoPower.Var2(:,1) ~= 0, :);

AvgEventDuration( :, all(~AvgEventDuration,1) ) = [];
distances = (pdist(AvgEventDuration', 'euclidean'));
dissimilarities = squareform(distances); 

clear colAvg
clear subAvg
for i = 1: length(dissimilarities)
    colAvg(i, :) = sum(dissimilarities(:,i)) ./ sum(dissimilarities~=0, 1);
    subAvg(i,:) = mean(colAvg(i,:)); 
end

OverallDistance = mean(subAvg); 
OverallSD = std(subAvg); 
Z = (subAvg - OverallDistance)/OverallSD; 

include = find(Z < 3); 
exclude = find(Z > 3); %  THESE ARE THE SUBJECTS YOU NEED TO DROP

subjectID_exclude = IDtoPower(exclude, :);
subjectID_include = IDtoPower(include,:);
disp(subjectID_exclude.idvalues); 

newPower = AvgEventDuration(:, include); 
newDistances = pdist(newPower', 'euclidean'); 
NewDissimilarities = squareform(newDistances);

[Y] = cmdscale(NewDissimilarities,2);
plot(Y(:,1), Y(:,2), '.'); 

save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/BetaEventDuration_NoOutliers.mat'), 'subjectID_include')






