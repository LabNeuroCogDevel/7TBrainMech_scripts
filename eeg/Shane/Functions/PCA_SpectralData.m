
addpath('H:\Projects\7TBrainMech\scripts\eeg\toolbox\SpectralEvents-master')

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

addpath(('Z:/DB_SQL/'));

all_ages = db_query('select id ||''_''|| to_char(vtimestamp,''YYYYMMDD'') as IDvalues, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg''  order by id, age ');
all_ages.idvalues= char(all_ages.idvalues);

for j = 1 : length(setfiles0)

    idvalues(j,:) = (setfiles0(j).name(1:14));
end

%% Principal Component Analysis- Gamma Avg Power
%combine PCAs with ages 
% T = table(idvalues, AvgPower');
% T = T(T.Var2(:,1) ~= 0, :);
% AvgPower( :, all(~AvgPower,1) ) = [];




[coeff, score, latent, tsquared, explained, mu] = pca(subjectID_include.Var2); 
Xcentered = score*coeff'; 
biplot(coeff(:,1:2),'scores',score(:,1:2));


plot(1:length(explained), explained)

varNames = {'idvalues', 'scores'}; 

PCAtable = table(subjectID_include.idvalues, score,'VariableNames', varNames);
all_info = innerjoin(PCAtable, all_ages);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_AvgPower_PCA_scores.csv'));

chanlocTable = table(chanlocs);

for i = 1:10
h = plot_topography(labels, coeff(:,i), 0, chanlocs);
name = sprintf('Gamma_AP_Component_%d', i);  
saveas(h, ['H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Gamma\' name], 'png')
end


%% Principal Component Analysis- Gamma Peak Power
%combine PCAs with ages 
% T = table(idvalues, peakPower');
% T = T(T.Var2(:,1) ~= 0, :);
% peakPower( :, all(~peakPower,1) ) = [];


[coeff, score, latent, tsquared, explained, mu] = pca(subjectID_include.Var2); 
Xcentered = score*coeff'; 
biplot(coeff(:,1:2),'scores',score(:,1:2));


plot(1:length(explained), explained)

varNames = {'idvalues', 'scores'}; 

PCAtable = table(subjectID_include.idvalues, score,'VariableNames', varNames);
all_info = innerjoin(PCAtable, all_ages);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_PeakPower_PCA_scores.csv'));

chanlocTable = table(chanlocs);

for i = 1:10
h = plot_topography(labels, coeff(:,i), 0, chanlocs);
name = sprintf('Gamma_PP_Component_%d', i);  
saveas(h, ['H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Gamma\' name], 'png')
end



%% Principal Component Analysis- Theta avg power
%combine PCAs with ages 
% T = table(idvalues, AvgPower');
% T = T(T.Var2(:,1) ~= 0, :);
% AvgPower( :, all(~AvgPower,1) ) = [];


[coeff, score, latent, tsquared, explained, mu] = pca(subjectID_include.Var2); 
Xcentered = score*coeff'; 
biplot(coeff(:,1:2),'scores',score(:,1:2));


plot(1:length(explained), explained)

varNames = {'idvalues', 'scores'}; 

PCAtable = table(subjectID_include.idvalues, score,'VariableNames', varNames);
all_info = innerjoin(PCAtable, all_ages);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_AP_PCA_scores.csv'));

chanlocTable = table(chanlocs);

for i = 1:10
h = plot_topography(labels, coeff(:,i), 0, chanlocs);
name = sprintf('Theta_AP_Component_%d', i);  
saveas(h, ['H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Theta\' name], 'png')
end



%% Principal Component Analysis- Theta peak power
%combine PCAs with ages 
% T = table(idvalues, peakPower');
% T = T(T.Var2(:,1) ~= 0, :);
% peakPower( :, all(~peakPower,1) ) = [];


[coeff, score, latent, tsquared, explained, mu] = pca(subjectID_include.Var2); 
Xcentered = score*coeff'; 
biplot(coeff(:,1:2),'scores',score(:,1:2));


plot(1:length(explained), explained)

varNames = {'idvalues', 'scores'}; 

PCAtable = table(subjectID_include.idvalues, score,'VariableNames', varNames);
all_info = innerjoin(PCAtable, all_ages);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Theta/Theta_PP_PCA_scores.csv'));

chanlocTable = table(chanlocs);

for i = 1:10
h = plot_topography(labels, coeff(:,i), 0, chanlocs);
name = sprintf('Theta_PP_Component_%d', i);  
saveas(h, ['H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Theta\' name], 'png')
end


%% Principal Component Analysis- Beta avg power
%combine PCAs with ages 
% T = table(idvalues, AvgPower');
% T = T(T.Var2(:,1) ~= 0, :);
% AvgPower( :, all(~AvgPower,1) ) = [];


[coeff, score, latent, tsquared, explained, mu] = pca(subjectID_include.Var2); 
Xcentered = score*coeff'; 
biplot(coeff(:,1:2),'scores',score(:,1:2));


plot(1:length(explained), explained)

varNames = {'idvalues', 'scores'}; 

PCAtable = table(subjectID_include.idvalues, score,'VariableNames', varNames);
all_info = innerjoin(PCAtable, all_ages);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_AP_PCA_scores.csv'));

chanlocTable = table(chanlocs);

for i = 1:10
h = plot_topography(labels, coeff(:,i), 0, chanlocs);
name = sprintf('Beta_AP_Component_%d', i);  
saveas(h, ['H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Beta\' name], 'png')
end



%% Principal Component Analysis- Beta peak power
%combine PCAs with ages 
% T = table(idvalues, peakPower');
% T = T(T.Var2(:,1) ~= 0, :);
% peakPower( :, all(~peakPower,1) ) = [];


[coeff, score, latent, tsquared, explained, mu] = pca(subjectID_include.Var2); 
Xcentered = score*coeff'; 
biplot(coeff(:,1:2),'scores',score(:,1:2));


plot(1:length(explained), explained)

varNames = {'idvalues', 'scores'}; 

PCAtable = table(subjectID_include.idvalues, score,'VariableNames', varNames);
all_info = innerjoin(PCAtable, all_ages);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_PP_PCA_scores.csv'));

chanlocTable = table(chanlocs);

for i = 1:10
h = plot_topography(labels, coeff(:,i), 0, chanlocs);
name = sprintf('Beta_PP_Component_%d', i);  
saveas(h, ['H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\Beta\' name], 'png')
end



