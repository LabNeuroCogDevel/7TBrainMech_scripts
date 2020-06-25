
function [] = fieldtripToolbox()

addpath(genpath('Functions'));
addpath('/Volumes/Hera/Projects/7TBrainMech/scripts/fieldtrip-20191127')
ft_defaults

datapath = hera('/Projects/7TBrainMech/scripts/eeg/Shane/Prep/AfterWhole/ICAwholeClean_homogenize');

%load in all the delay files 
setfiles0 = dir([datapath,'/*icapru.set']);
setfiles = {};

for epo = 1:length(setfiles0)
    setfiles{epo,1} = fullfile(datapath, setfiles0(epo).name); % cell array with EEG file names
    % setfiles = arrayfun(@(x) fullfile(folder, x.name), setfiles(~[setfiles.isdir]),folder, 'Uni',0); % cell array with EEG file names
end



for i = 1 : length(setfiles)
    
    inputfile = setfiles{i};
    
    clear events
    clear data
    clear hdr
    
    hdr = ft_read_header(inputfile);
    data = ft_read_data(inputfile, 'header', hdr);
    events = ft_read_event(inputfile, 'header', hdr);
    
    cfg = [];
    cfg.dataset = inputfile;
    cfg.headerfile = inputfile;
    cfg.channel = 'all';
    cfg.trialdef.eventtype = 'trigger';
    cfg.trialdef.eventvalue = '4';
    cfg.trialdef.prestim = 0;
    cfg.trialdef.poststim = 6;
    cfg.trialfun = 'ft_trialfun_general';
    cfg.trialdef.ntrials = 95;
    cfg.event = events;
    
    try 
        
        [cfg]= ft_definetrial(cfg);
        
    catch
        continue;
    end
    
    
    [data] = ft_preprocessing(cfg);
    
    
    %redefine the trails to be between 2-4 seconds of the delay period
    cfg.trl = [];
    cfg = rmfield(cfg, 'trl');
    cfg.toilim = [4 6];
    data = ft_redefinetrial(cfg, data);


    cfg.method = 'mtmfft';
    cfg.output = 'pow';
    cfg.channel = {'F3', 'F5', 'F1'};
    cfg.taper = 'hanning';
    cfg.foilim = [30 40];
    cfg.tapsmofrq = 4;
    
    [freq] = ft_freqanalysis(cfg, data);
        
    avg_power = mean(mean(freq.powspctrm,2));
    
    all_power(i) = avg_power;
    
end

save('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/DLFPC_ROI/low_gamma/4_6_Seconds/all_power_4_6_secs.mat', 'all_power');

% [Ages, subjects, indices] = findAges(setfiles0, setfiles);
% 
% powers = all_power(indices>0);
% 
% removeSubs = find(powers > 0); 
% Ages = Ages(removeSubs',:);
% power = powers(removeSubs);
% 
% 
% [b, dev, stats] = glmfit(Ages(:,2), log(power));
% include = find(abs(zscore(stats.residd)) < 2.5); 
% 
% correctedPower = power(include);
% correctedAges = Ages(include,:);
% correctedIDs = IDs(include);
% scatter(correctedAges(:,2), log(correctedPower)); 
% 
% [b, dev, stats] = glmfit(correctedAges(:,2), log(correctedPower));
% yfit = glmval(b, correctedAges, 'identity'); 
% 
% hold on; 
% plot(correctedAges, yfit); 
% xlabel('Ages');
% ylabel('Power');
% 
%% compare time windows of gamma

all_power_2_4 =  load('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/2_4_Seconds/all_power_2_4_secs.mat');
all_power_4_6 = load('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/4_6_Seconds/all_power_4_6_secs.mat');

all_power_2_4 = all_power_2_4.all_power;
all_power_4_6 = all_power_4_6.all_power;

% load in 2-4 second data
[idx1, Ages, IDvalues] = findAges(setfiles0, setfiles);
all_power_24 = [all_power_2_4 ; IDvalues];

noPower_24 = find(all_power_24(1,:) == 0);
hasPower_24 = find(all_power_24(1,:) > 0 ); 
subNoPower_24 = all_power_24(2,noPower_24);

leftOver_powers_24 = all_power_24(:,hasPower_24);
leftOver_powers_24 = leftOver_powers_24';


% load in 4-6 second data
all_power_46 = [all_power_4_6 ; IDvalues];

noPower_46 = find(all_power_46(1,:) == 0);
hasPower_46 = find(all_power_46(1,:) > 0 ); 
subNoPower_46 = all_power_46(2,noPower_46);

leftOver_powers_46 = all_power_46(:,hasPower_46);
leftOver_powers_46 = leftOver_powers_46';



% remove subs that have no power from age matrix
%2-4 seconds
AgesIdx_24 = ismember(Ages(:,1), leftOver_powers_24(:,2));
AgeMatrix_24 = Ages(AgesIdx_24,:);

powerIdx_24 = ismember(leftOver_powers_24(:,2), AgeMatrix_24(:,1));
PowerMatrix_24 = leftOver_powers_24(powerIdx_24,:);

%4-6 seconds
AgesIdx_46 = ismember(Ages(:,1), leftOver_powers_46(:,2));
AgeMatrix_46 = Ages(AgesIdx_46,:);

powerIdx_46 = ismember(leftOver_powers_46(:,2), AgeMatrix_46(:,1));
PowerMatrix_46 = leftOver_powers_46(powerIdx_46,:);


% correct 2-4 second data 
[b, dev, stats] = glmfit(AgeMatrix_24(:,2), log(PowerMatrix_24(:,1)));
include_2_4 = find(abs(zscore(stats.residd)) < 2.5); 

correctedPower_24 = PowerMatrix_24(include_2_4,:);
correctedAges_24 = AgeMatrix_24(include_2_4,:); 

[b_24, dev_24, stats_24] = glmfit(correctedAges_24(:,2), log(correctedPower_24(:,1)));
yfit_24 = glmval(b_24, correctedAges_24(:,2), 'identity'); 

% correct 4-6 second data 
[b, dev, stats] = glmfit(AgeMatrix_46(:,2), log(PowerMatrix_46(:,1)));
include_4_6 = find(abs(zscore(stats.residd)) < 2.5); 

correctedPower_46 = PowerMatrix_46(include_4_6,:);
correctedAges_46 = AgeMatrix_46(include_4_6,:);


[b_46, dev_46, stats_46] = glmfit(correctedAges_46(:,2), log(correctedPower_46(:,1)));
yfit_46 = glmval(b_46, correctedAges_46(:,2), 'identity'); 


age_vs_power_2_4 = [correctedAges_24 correctedPower_24];
save('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/2_4_Seconds/avg_vs_power_24.mat', 'age_vs_power_2_4');

age_vs_power_4_6 = [correctedAges_46 correctedPower_46];
save('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/4_6_Seconds/avg_vs_power_46.mat', 'age_vs_power_4_6');


%% FIND A WAY TO DELETE THE SUBJECTS WHO DONT HAVE MATCHING AGE AND POWER DATAs

correctedAges_24_table = table(correctedAges_24(:,1), correctedAges_24(:,2),  'VariableNames',{'SubIDs','Ages'});
correctedPower_24_table = table(correctedPower_24(:,1), correctedPower_24(:,2),'VariableNames',{'Power','SubIDs'});

correctedAges_46_table = table(correctedAges_46(:,1), correctedAges_46(:,2),  'VariableNames',{'SubIDs','Ages'});
correctedPower_46_table = table(correctedPower_46(:,1), correctedPower_46(:,2),'VariableNames',{'Power','SubIDs'});


final_matrix_24 = innerjoin(correctedAges_24_table, correctedPower_24_table);
final_matrix_46 = innerjoin(correctedAges_46_table, correctedPower_46_table);

save('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/2_4_Seconds/avg_vs_power_24.mat', 'final_matrix_24');
 
save('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/4_6_Seconds/avg_vs_power_46.mat', 'final_matrix_46');

%% find subjects in both 2-4 seconds and 4-6 seconds

bothEpochs =  innerjoin(final_matrix_46, final_matrix_24,'LeftKeys',1,'RightKeys', 1);

%% save info as tables

p24 = load('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/2_4_Seconds/avg_vs_power_24.mat');
p46 = load('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/4_6_Seconds/avg_vs_power_46.mat');
%%
p24_tbl = p24.final_matrix_24;
p24_tbl.epoch = repmat('24', [height(p24_tbl) 1]);

p46_tbl = p46.final_matrix_46;
p46_tbl.epoch = repmat('46', [height(p46_tbl) 1]);

power_tbl = [p24_tbl; p46_tbl];
power_tbl.Properties.VariableNames{1} = 'Subject';
power_tbl.Properties.VariableNames{2} = 'Age';
power_tbl.Properties.VariableNames{3} = 'Power';

writetable(power_tbl, '/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/power_table.csv');




   
%% plot all subjects
scatter(final_matrix_24(:,2), log(final_matrix_24(:,3)));
hold on;
scatter(final_matrix_46(:,2), log(final_matrix_46(:,3)));


[b_24, dev_24, stats_24] = glmfit(final_matrix_24(:,2), log(final_matrix_24(:,3)));
yfit_24 = glmval(b_24, final_matrix_24(:,2), 'identity'); 

[b_46, dev_46, stats_46] = glmfit(final_matrix_46(:,2), log(final_matrix_46(:,3)));
yfit_46 = glmval(b_46, final_matrix_46(:,2), 'identity'); 

hold on; 
plot(final_matrix_24(:,2), yfit_24); 

hold on; 
plot(final_matrix_46(:,2), yfit_46); 

xlabel('Ages');
ylabel('Power');
legend('2 to 4 Seconds','4 to 6 Seconds', '2 to 4 Seconds','4 to 6 Seconds'); 


%% over 20 (HAVENT FIXED FOR SUBJECTS IN BOTH EPOCHS)
over20_correctedAges_idx = find(correctedAges >= 20);
over20_correctedAges = correctedAges(over20_correctedAges_idx);

over20_correctedPower_24 = correctedPower_2_4(over20_correctedAges_idx);
over20_correctedPower_46 = correctedPower_4_6(over20_correctedAges_idx);

[b_24, dev_24, stats_24] = glmfit(over20_correctedAges, log(over20_correctedPower_24));
yfit_24 = glmval(b_24, over20_correctedAges, 'identity'); 

[b_46, dev_46, stats_46] = glmfit(over20_correctedAges, log(over20_correctedPower_46));
yfit_46 = glmval(b_46, over20_correctedAges, 'identity'); 


%% Plot over 20
scatter(over20_correctedAges, log(over20_correctedPower_24));
hold on;
scatter(over20_correctedAges, log(over20_correctedPower_46)); 

hold on; 
plot(over20_correctedAges, yfit_24); 

hold on; 
plot(over20_correctedAges, yfit_46); 

xlabel('Ages');
ylabel('Power');
legend('2 to 4 Seconds','4 to 6 Seconds', '2 to 4 Seconds','4 to 6 Seconds'); 









