restoredefaultpath
addpath('Functions')
% addpath(genpath('Functions/resources/Euge/Toolbox_v2018'))

% Functions/resources/Euge/Toolbox_v2018/Toolbox_v2018/Toolbox.m
% Toolbox
% EEG; File -> path to data -> 
% /Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/epochcleanTF
% imagesc(squeeze(s_erps{2}(1,:,:)))
%% Parameters to choose
%Rois Parietal (R y L), Frontal lateral (R y L), partially invented
cfg.rois{1}=[5 6 7]; %left-frontal
cfg.rois{2}=[40 39 38]; %rigth-frontal
cfg.rois{3}=[22 23 31]; %left-parietal
cfg.rois{4}=[31 59 58]; %right-parietal
cfg.rois{5}=[cfg.rois{1} cfg.rois{2} cfg.rois{3} cfg.rois{4}]; % All
cfg.rois{6} = [32 23 59 31 24 60 58];
ROI = 5;

files = dir(hera('Projects/7TBrainMech/scripts/eeg/Alethia/Results/TF/Fixation/*.mat'));
% files = dir('C:\Users\Amelie\Documents\LNCDpasantia\data\test/*.mat');
com
% Regios for the slopes
Bfullrange = [1:45];% seems ether
Buprange = [22:45];
Blowrange = [1:22];
PSD = [];PSDdb = [];PSD_i = [];
gammaBroad_i = [];betaFull_i = []; BetaUp_i = []; BetaLow_i = [];

for i = 1: length(files)
    subject = files(i).name;
    i
    filename = hera(['Projects/7TBrainMech/scripts/eeg/Alethia/Results/TF/Fixation/', subject]);
    load(filename)
    timebins = find(timesout>0);

    i
    for ROI = 1:length(cfg.rois)
        for c = 1:length(cfg.rois{ROI})
            for j = 1:length(freqs)
                [PSDdb(j,c),PSD(j,c)] = calcPSD( s_erps,timebins,j,cfg.rois{ROI}(c),s_mbases );
            end
            [bettaFull(c),BettaUp(c),BettaLow(c)] = extractBettas(PSD(:,c),Bfullrange,Buprange,Blowrange,freqs);
            
        end
        
        gammaBroad_i(ROI,i) = mean(mean(PSD(Buprange,:),2));
        betaFull_i(ROI,i) = mean(bettaFull,2);
        BetaUp_i(ROI,i) = mean(BettaUp,2);
        BetaLow_i(ROI,i) = mean(BettaLow,2);
    end
    %     loglog(freqs(1:45), PSD_i(1:45,i),'-s')
    %     grid on
    
end

%% Gamma Analysis
gammaAnalysis(gammaBroad_i, freqs, files, cfg);


%% Acomodar valores en la tabla final
EEG_Power_variables = [gammaBroad_i',betaFull_i',BetaUp_i',BetaLow_i'];

col_header = {'SujFileNumber','GammaR1','Gamma2','GammaR3','Gamma4','Gamma5',...
    'BFullR1','BFullR2','BFullR3','BFullR4','BFullR5',...
    'BHigR1','BHigR2','BHigR3','BHig4','BHig5',...
    'BLowR1','BLowR2','BLowR3','BLow4','BLow5'};

for col = 1:length(col_header)
col_header{col} = strcat(col_header{col});
end

data_cells=num2cell(EEG_Power_variables);     %Convert data to cell array
for s = 1:length(EEG_Power_variables)
row_header(s)={[files(s).name]};     %Column cell array (for row labels)
end
output_matrix=[col_header; row_header' data_cells];     %Join cell arrays
xlswrite(['H:\Projects\7TBrainMech\scripts\eeg\Alethia\Results\TF\Power_Variables.xls'],output_matrix);     %Write data and both headers

