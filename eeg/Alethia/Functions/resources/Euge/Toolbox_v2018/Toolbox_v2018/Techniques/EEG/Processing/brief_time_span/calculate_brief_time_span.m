function calculate_brief_time_span(EEG,condition_1, condition_2,bandpassRange,epoch_window,base_window,method,newFileName)
%Calculates brief time span connectivity for two conditions. This method
%filters the iEEG signal in a desired frequency range. Then the correlation coefficient is calculated.

%INPUTS:
%EEG: Full EEG, not epoched to filter

%condition_1: name of condition_1 (must be a cell array)
%condition_2: name of condition_2 (must be a cell array)
%bandpassRange: a two value vector with the frequency range to be filtered,
%               e.g. bandpassRange = [minfreq maxfreq];
%epoch_window: vector of two values used to determine epoch window
%base_window: vector of two values used to determine base window 

%filter EEG signal in desired frequency range
%EEG = pop_eegfilt( EEG, bandpassRange(1,1), bandpassRange(1,2), [], [0], 0, 0, 'fir1', 0);
EEG = pop_eegfiltnew(EEG, bandpassRange(1,1), bandpassRange(1,2), 1690, 0, [], 0);

%epoch signal
data = EEG.data;
types = unique({EEG.event.type});
% str = '';
% for i=1:length(types)
%     if isequal(str,'')
%         str = types{i};
%     else
%         str = [str ' ' types{i}];
%     end
% end
% types = strsplit(str);

[ EEG ] = ieeg_epoch(types, epoch_window, base_window,'', EEG);

%filter by conditions
EEG_condition_1 = filter_epochs(strsplit(condition_1), EEG);
signal1 = EEG_condition_1.data;

EEG_condition_2 = filter_epochs(strsplit(condition_2), EEG);
signal2 = EEG_condition_2.data;

%calculo correlacion 
chanNr = size(signal1,1);

cond1TrialNr = size(signal1,3);
corrCond1 = zeros(chanNr,chanNr,cond1TrialNr);

for i = 1 : cond1TrialNr
    [R1,P,RLO,RUP] = corrcoef(signal1(:,:,i)');
    corrCond1(:,:,i) = R1;
end

cond2TrialNr = size(signal2,3);
corrCond2 = zeros(chanNr,chanNr,cond2TrialNr);

for j = 1 : cond2TrialNr
    [R2,P,RLO,RUP]=corrcoef(signal2(:,:,j)');
    corrCond2(:,:,j) = R2;
end


switch method
    case 'perm'
        [t df pvals] = statcond({corrCond1,corrCond2}, 'mode', 'perm','paired','off','tail','both','naccu',1000);   %calcula permutaciones
    case 'boot'
        [t df pvals] = statcond({corrCond1,corrCond2}, 'mode', 'bootstrap','paired','off','tail','both','naccu',1000);   %calcula permutaciones
    case 'ttest'
        [h,p,ci,stats] = ttest2(data1,data2);
        t = stats.tstat;
end        

matrixFilename = [newFileName '-' condition_1 '-' condition_2 '.mat'];
%str = ['save ' matrixFilename ' t df pvals'];
%eval(str)
save(matrixFilename,'t','df','pvals');
