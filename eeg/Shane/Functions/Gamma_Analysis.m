function [] = Gamma_Analysis()

addpath(genpath('Functions'));
addpath(genpath('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/toolbox/eeglab14_1_2b'))
addpath('/Volumes/Zeus/DB_SQL')

datapath = hera('/Projects/7TBrainMech/scripts/eeg/Shane/Prep/AfterWhole/PermutEpoch');

%load in all the delay files 
setfiles0 = dir([datapath,'/*Delay.set']);
setfiles = {};
for epo = 1:length(setfiles0)
setfiles{epo,1} = fullfile(datapath, setfiles0(epo).name); % cell array with EEG file names
% setfiles = arrayfun(@(x) fullfile(folder, x.name), setfiles(~[setfiles.isdir]),folder, 'Uni',0); % cell array with EEG file names
end

for i = 1:length(setfiles)
    inputfile = setfiles(i);
    EEG = pop_loadset(inputfile);
    newEEG = EEG; 
    

    n = length(newEEG.data);
    fs = EEG.srate; 
    f = (0:n-1)*(fs/n);
    
    FourierTransform = fft(newEEG.data,[],2);
    
    ChanSix_fft = (mean(FourierTransform(6,:,:),3));
   
    power = abs(ChanSix_fft).^2;

    
    All_power(i,:) = power;
    
end



%% Gamma

gamma = find(f>= 40 & f <= 75);
gammaValues = f(gamma);
powerValues = All_power(:,gamma);

plot(gammaValues, powerValues);
xlabel('Freq');
ylabel('Power');

%% Extract Ages
AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/ERPs/EdaDI.xlsx'));

all_ages = db_query('select id, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg'' and visitno < 2 order by id, age ');


for j = 1 : length(setfiles0)
    
    IDvalues = (setfiles0(j).name(1:5));

    IDX = strmatch(IDvalues, all_ages.id);
    
        if isempty(IDX)
            IDX = 0;
            
        end
        
    indices(j) = IDX;
    
end

subjects = setfiles(indices>0);
Ages = all_ages.age(indices>0);


%% Power vs Age 
plot(f(1:100),All_power(indices>0,1:100)); hold on; plot(f(1:100), mean(All_power(:,1:100)), 'k', 'LineWidth', 2);

for i = 1:length(f(1:100))
    ibin = All_power(indices>0,i);
    
    correlation(i) = corr(Ages, ibin);

 
end

%%


avgPower = avgPower(indices>0);
AllPower_ageIDX = All_power(indices>0,:);
avgAllPower_ageIDX = mean(AllPower_ageIDX, 2);

b = glmfit(Ages, avgAllPower_ageIDX);
yfit = glmval(b,Ages,'identity');

scatter(Ages, avgAllPower_ageIDX);







average = mean(avgPower);
sd = std(avgPower);
include = find(avgPower < 2.5*sd);
avgPower = avgPower(include);
Ages = Ages(include);


scatter(Ages,avgPower);

fit = polyfit(Ages,avgPower',1);

predValues = polyval(fit, Ages);

hold on;
plot(Ages, predValues);

ylabel('Power');
xlabel('Age');




