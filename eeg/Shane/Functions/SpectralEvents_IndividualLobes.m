
datapath = hera('/Projects/7TBrainMech/scripts/eeg/Shane/Prep/AfterWhole/ICAwholeClean_homogenize');

%load in all the delay files
setfiles0 = dir([datapath,'/*icapru.set']);
setfiles = {};

for epo = 1:length(setfiles0)
    setfiles{epo,1} = fullfile(datapath, setfiles0(epo).name); % cell array with EEG file names
    % setfiles = arrayfun(@(x) fullfile(folder, x.name), setfiles(~[setfiles.isdir]),folder, 'Uni',0); % cell array with EEG file names
end



%% Look at individual lobes Gamma
% Frontal Lobe Gamma

FrontalLobe_AvgEventDuration  = AvgEventDuration([2:7 34:41], :);
FrontalLobe_AvgEventNumber = AvgEventNumber([2:7 34:41], :);
FrontalLobe_AvgPower = AvgPower([2:7 34:41], :);
FrontalLobe_peakPower = peakPower([2:7 34:41], :);

AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/ERPs/EdaDI.xlsx'));

addpath(('Z:/DB_SQL/'));

all_ages = db_query('select id ||''_''|| to_char(vtimestamp,''YYYYMMDD'') as IDvalues, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg''  order by id, age ');
all_ages.idvalues= char(all_ages.idvalues);

for j = 1 : length(setfiles0)
    
    idvalues(j,:) = (setfiles0(j).name(1:14));
end


FrontalLobe_MeanAvgEventNumber = mean(FrontalLobe_AvgEventNumber,1)';
FrontalLobe_MeanAvgEventDuration = mean(FrontalLobe_AvgEventDuration,1)'; 
FrontalLobe_MeanAvgPower = mean(FrontalLobe_AvgPower, 1)'; 
FrontalLobe_MeanpeakPower = mean(FrontalLobe_peakPower, 1)'; 


T = table(idvalues, FrontalLobe_MeanAvgEventNumber, FrontalLobe_MeanAvgEventDuration, FrontalLobe_MeanAvgPower, FrontalLobe_MeanpeakPower);
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/FrontalLobe_Gamma_Spectral_Analysis_Table.mat'), 'T')

all_info = innerjoin(T, all_ages);



all_info = all_info(all_info.FrontalLobe_MeanAvgEventNumber ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/FrontalLobe_Gamma_Spectral_Analysis_Table_all.csv'));


% Parietal lobe gamma
ParietalLobe_AvgEventDuration  = AvgEventDuration([19:26 30:31 55:62], :);
ParietalLobe_AvgEventNumber = AvgEventNumber([19:26 30:31 55:62], :);
ParietalLobe_AvgPower = AvgPower([19:26 30:31 55:62], :);
ParietalLobe_peakPower = peakPower([19:26 30:31 55:62], :);

AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/ERPs/EdaDI.xlsx'));

addpath(('Z:/DB_SQL/'));

all_ages = db_query('select id ||''_''|| to_char(vtimestamp,''YYYYMMDD'') as IDvalues, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg''  order by id, age ');
all_ages.idvalues= char(all_ages.idvalues);

for j = 1 : length(setfiles0)
    
    idvalues(j,:) = (setfiles0(j).name(1:14));
end


ParietalLobe_MeanAvgEventNumber = mean(ParietalLobe_AvgEventNumber,1)';
ParietalLobe_MeanAvgEventDuration = mean(ParietalLobe_AvgEventDuration,1)'; 
ParietalLobe_MeanAvgPower = mean(ParietalLobe_AvgPower, 1)'; 
ParietalLobe_MeanpeakPower = mean(ParietalLobe_peakPower, 1)'; 


T = table(idvalues, ParietalLobe_MeanAvgEventNumber, ParietalLobe_MeanAvgEventDuration, ParietalLobe_MeanAvgPower, ParietalLobe_MeanpeakPower);
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/ParietalLobe_Gamma_Spectral_Analysis_Table.mat'), 'T')

all_info = innerjoin(T, all_ages);



all_info = all_info(all_info.ParietalLobe_MeanAvgEventNumber ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/ParietalLobe_Gamma_Spectral_Analysis_Table_all.csv'));


% Occipital lobe gamma
OccipitalLobe_AvgEventDuration  = AvgEventDuration([27,29,63], :);
OccipitalLobe_AvgEventNumber = AvgEventNumber([27,29,63], :);
OccipitalLobe_AvgPower = AvgPower([27,29,63], :);
OccipitalLobe_peakPower = peakPower([27,29,63], :);

AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/ERPs/EdaDI.xlsx'));

addpath(('Z:/DB_SQL/'));

all_ages = db_query('select id ||''_''|| to_char(vtimestamp,''YYYYMMDD'') as IDvalues, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg''  order by id, age ');
all_ages.idvalues= char(all_ages.idvalues);

for j = 1 : length(setfiles0)
    
    idvalues(j,:) = (setfiles0(j).name(1:14));
end


OccipitalLobe_MeanAvgEventNumber = mean(OccipitalLobe_AvgEventNumber,1)';
OccipitalLobe_MeanAvgEventDuration = mean(OccipitalLobe_AvgEventDuration,1)'; 
OccipitalLobe_MeanAvgPower = mean(OccipitalLobe_AvgPower, 1)'; 
OccipitalLobe_MeanpeakPower = mean(OccipitalLobe_peakPower, 1)'; 


T = table(idvalues, OccipitalLobe_MeanAvgEventNumber, OccipitalLobe_MeanAvgEventDuration, OccipitalLobe_MeanAvgPower, OccipitalLobe_MeanpeakPower);
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/OccipitalLobe_Gamma_Spectral_Analysis_Table.mat'), 'T')

all_info = innerjoin(T, all_ages);


all_info = all_info(all_info.OccipitalLobe_MeanAvgEventNumber ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/OccipitalLobe_Gamma_Spectral_Analysis_Table_all.csv'));




% Central gamma
Central_AvgEventDuration  = AvgEventDuration([8:10, 13:18, 32, 42:45, 48, 54], :);
Central_AvgEventNumber = AvgEventNumber([8:10, 13:18, 32, 42:45, 48, 54], :);
Central_AvgPower = AvgPower([8:10, 13:18, 32, 42:45, 48, 54], :);
Central_peakPower = peakPower([8:10, 13:18, 32, 42:45, 48, 54], :);

AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/ERPs/EdaDI.xlsx'));

addpath(('Z:/DB_SQL/'));

all_ages = db_query('select id ||''_''|| to_char(vtimestamp,''YYYYMMDD'') as IDvalues, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg''  order by id, age ');
all_ages.idvalues= char(all_ages.idvalues);

for j = 1 : length(setfiles0)
    
    idvalues(j,:) = (setfiles0(j).name(1:14));
end


Central_MeanAvgEventNumber = mean(Central_AvgEventNumber,1)';
Central_MeanAvgEventDuration = mean(Central_AvgEventDuration,1)'; 
Central_MeanAvgPower = mean(Central_AvgPower, 1)'; 
Central_MeanpeakPower = mean(Central_peakPower, 1)'; 


T = table(idvalues, Central_MeanAvgEventNumber, Central_MeanAvgEventDuration, Central_MeanAvgPower, Central_MeanpeakPower);
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Central_Gamma_Spectral_Analysis_Table.mat'), 'T')

all_info = innerjoin(T, all_ages);


all_info = all_info(all_info.Central_MeanAvgEventNumber ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Central_Gamma_Spectral_Analysis_Table_all.csv'));


%% Look at individual lobes theta 
% Frontal Lobe Theta

FrontalLobe_AvgEventDuration  = AvgEventDuration([2:7 34:41], :);
FrontalLobe_AvgEventNumber = AvgEventNumber([2:7 34:41], :);
FrontalLobe_AvgPower = AvgPower([2:7 34:41], :);
FrontalLobe_peakPower = peakPower([2:7 34:41], :);

AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/ERPs/EdaDI.xlsx'));

addpath(('Z:/DB_SQL/'));

all_ages = db_query('select id ||''_''|| to_char(vtimestamp,''YYYYMMDD'') as IDvalues, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg''  order by id, age ');
all_ages.idvalues= char(all_ages.idvalues);

for j = 1 : length(setfiles0)
    
    idvalues(j,:) = (setfiles0(j).name(1:14));
end


FrontalLobe_MeanAvgEventNumber = mean(FrontalLobe_AvgEventNumber,1)';
FrontalLobe_MeanAvgEventDuration = mean(FrontalLobe_AvgEventDuration,1)'; 
FrontalLobe_MeanAvgPower = mean(FrontalLobe_AvgPower, 1)'; 
FrontalLobe_MeanpeakPower = mean(FrontalLobe_peakPower, 1)'; 


T = table(idvalues, FrontalLobe_MeanAvgEventNumber, FrontalLobe_MeanAvgEventDuration, FrontalLobe_MeanAvgPower, FrontalLobe_MeanpeakPower);
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/FrontalLobe_Theta_Spectral_Analysis_Table.mat'), 'T')

all_info = innerjoin(T, all_ages);



all_info = all_info(all_info.FrontalLobe_MeanAvgEventNumber ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/FrontalLobe_Theta_Spectral_Analysis_Table_all.csv'));


% Parietal lobe theta
ParietalLobe_AvgEventDuration  = AvgEventDuration([19:26 30:31 55:62], :);
ParietalLobe_AvgEventNumber = AvgEventNumber([19:26 30:31 55:62], :);
ParietalLobe_AvgPower = AvgPower([19:26 30:31 55:62], :);
ParietalLobe_peakPower = peakPower([19:26 30:31 55:62], :);

AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/ERPs/EdaDI.xlsx'));

addpath(('Z:/DB_SQL/'));

all_ages = db_query('select id ||''_''|| to_char(vtimestamp,''YYYYMMDD'') as IDvalues, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg''  order by id, age ');
all_ages.idvalues= char(all_ages.idvalues);

for j = 1 : length(setfiles0)
    
    idvalues(j,:) = (setfiles0(j).name(1:14));
end


ParietalLobe_MeanAvgEventNumber = mean(ParietalLobe_AvgEventNumber,1)';
ParietalLobe_MeanAvgEventDuration = mean(ParietalLobe_AvgEventDuration,1)'; 
ParietalLobe_MeanAvgPower = mean(ParietalLobe_AvgPower, 1)'; 
ParietalLobe_MeanpeakPower = mean(ParietalLobe_peakPower, 1)'; 


T = table(idvalues, ParietalLobe_MeanAvgEventNumber, ParietalLobe_MeanAvgEventDuration, ParietalLobe_MeanAvgPower, ParietalLobe_MeanpeakPower);
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/ParietalLobe_Theta_Spectral_Analysis_Table.mat'), 'T')

all_info = innerjoin(T, all_ages);



all_info = all_info(all_info.ParietalLobe_MeanAvgEventNumber ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/ParietalLobe_Theta_Spectral_Analysis_Table_all.csv'));


% Occipital lobe Theta
OccipitalLobe_AvgEventDuration  = AvgEventDuration([27,29,63], :);
OccipitalLobe_AvgEventNumber = AvgEventNumber([27,29,63], :);
OccipitalLobe_AvgPower = AvgPower([27,29,63], :);
OccipitalLobe_peakPower = peakPower([27,29,63], :);

AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/ERPs/EdaDI.xlsx'));

addpath(('Z:/DB_SQL/'));

all_ages = db_query('select id ||''_''|| to_char(vtimestamp,''YYYYMMDD'') as IDvalues, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg''  order by id, age ');
all_ages.idvalues= char(all_ages.idvalues);

for j = 1 : length(setfiles0)
    
    idvalues(j,:) = (setfiles0(j).name(1:14));
end


OccipitalLobe_MeanAvgEventNumber = mean(OccipitalLobe_AvgEventNumber,1)';
OccipitalLobe_MeanAvgEventDuration = mean(OccipitalLobe_AvgEventDuration,1)'; 
OccipitalLobe_MeanAvgPower = mean(OccipitalLobe_AvgPower, 1)'; 
OccipitalLobe_MeanpeakPower = mean(OccipitalLobe_peakPower, 1)'; 


T = table(idvalues, OccipitalLobe_MeanAvgEventNumber, OccipitalLobe_MeanAvgEventDuration, OccipitalLobe_MeanAvgPower, OccipitalLobe_MeanpeakPower);
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/OccipitalLobe_Theta_Spectral_Analysis_Table.mat'), 'T')

all_info = innerjoin(T, all_ages);


all_info = all_info(all_info.OccipitalLobe_MeanAvgEventNumber ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/OccipitalLobe_Theta_Spectral_Analysis_Table_all.csv'));




% Central theta
Central_AvgEventDuration  = AvgEventDuration([8:10, 13:18, 32, 42:45, 48, 54], :);
Central_AvgEventNumber = AvgEventNumber([8:10, 13:18, 32, 42:45, 48, 54], :);
Central_AvgPower = AvgPower([8:10, 13:18, 32, 42:45, 48, 54], :);
Central_peakPower = peakPower([8:10, 13:18, 32, 42:45, 48, 54], :);

AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/ERPs/EdaDI.xlsx'));

addpath(('Z:/DB_SQL/'));

all_ages = db_query('select id ||''_''|| to_char(vtimestamp,''YYYYMMDD'') as IDvalues, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg''  order by id, age ');
all_ages.idvalues= char(all_ages.idvalues);

for j = 1 : length(setfiles0)
    
    idvalues(j,:) = (setfiles0(j).name(1:14));
end


Central_MeanAvgEventNumber = mean(Central_AvgEventNumber,1)';
Central_MeanAvgEventDuration = mean(Central_AvgEventDuration,1)'; 
Central_MeanAvgPower = mean(Central_AvgPower, 1)'; 
Central_MeanpeakPower = mean(Central_peakPower, 1)'; 


T = table(idvalues, Central_MeanAvgEventNumber, Central_MeanAvgEventDuration, Central_MeanAvgPower, Central_MeanpeakPower);
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Central_Theta_Spectral_Analysis_Table.mat'), 'T')

all_info = innerjoin(T, all_ages);


all_info = all_info(all_info.Central_MeanAvgEventNumber ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Central_Theta_Spectral_Analysis_Table_all.csv'));

%% Look at individual lobes Beta
% Frontal Lobe beta

FrontalLobe_AvgEventDuration  = AvgEventDuration([2:7 34:41], :);
FrontalLobe_AvgEventNumber = AvgEventNumber([2:7 34:41], :);
FrontalLobe_AvgPower = AvgPower([2:7 34:41], :);
FrontalLobe_peakPower = peakPower([2:7 34:41], :);

AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/ERPs/EdaDI.xlsx'));

addpath(('Z:/DB_SQL/'));

all_ages = db_query('select id ||''_''|| to_char(vtimestamp,''YYYYMMDD'') as IDvalues, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg''  order by id, age ');
all_ages.idvalues= char(all_ages.idvalues);

for j = 1 : length(setfiles0)
    
    idvalues(j,:) = (setfiles0(j).name(1:14));
end


FrontalLobe_MeanAvgEventNumber = mean(FrontalLobe_AvgEventNumber,1)';
FrontalLobe_MeanAvgEventDuration = mean(FrontalLobe_AvgEventDuration,1)'; 
FrontalLobe_MeanAvgPower = mean(FrontalLobe_AvgPower, 1)'; 
FrontalLobe_MeanpeakPower = mean(FrontalLobe_peakPower, 1)'; 


T = table(idvalues, FrontalLobe_MeanAvgEventNumber, FrontalLobe_MeanAvgEventDuration, FrontalLobe_MeanAvgPower, FrontalLobe_MeanpeakPower);
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/FrontalLobe_Beta_Spectral_Analysis_Table.mat'), 'T')

all_info = innerjoin(T, all_ages);



all_info = all_info(all_info.FrontalLobe_MeanAvgEventNumber ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/FrontalLobe_Beta_Spectral_Analysis_Table_all.csv'));


% Parietal lobe beta
ParietalLobe_AvgEventDuration  = AvgEventDuration([19:26 30:31 55:62], :);
ParietalLobe_AvgEventNumber = AvgEventNumber([19:26 30:31 55:62], :);
ParietalLobe_AvgPower = AvgPower([19:26 30:31 55:62], :);
ParietalLobe_peakPower = peakPower([19:26 30:31 55:62], :);

AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/ERPs/EdaDI.xlsx'));

addpath(('Z:/DB_SQL/'));

all_ages = db_query('select id ||''_''|| to_char(vtimestamp,''YYYYMMDD'') as IDvalues, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg''  order by id, age ');
all_ages.idvalues= char(all_ages.idvalues);

for j = 1 : length(setfiles0)
    
    idvalues(j,:) = (setfiles0(j).name(1:14));
end


ParietalLobe_MeanAvgEventNumber = mean(ParietalLobe_AvgEventNumber,1)';
ParietalLobe_MeanAvgEventDuration = mean(ParietalLobe_AvgEventDuration,1)'; 
ParietalLobe_MeanAvgPower = mean(ParietalLobe_AvgPower, 1)'; 
ParietalLobe_MeanpeakPower = mean(ParietalLobe_peakPower, 1)'; 


T = table(idvalues, ParietalLobe_MeanAvgEventNumber, ParietalLobe_MeanAvgEventDuration, ParietalLobe_MeanAvgPower, ParietalLobe_MeanpeakPower);
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/ParietalLobe_Beta_Spectral_Analysis_Table.mat'), 'T')

all_info = innerjoin(T, all_ages);



all_info = all_info(all_info.ParietalLobe_MeanAvgEventNumber ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/ParietalLobe_Beta_Spectral_Analysis_Table_all.csv'));


% Occipital lobe beta
OccipitalLobe_AvgEventDuration  = AvgEventDuration([27,29,63], :);
OccipitalLobe_AvgEventNumber = AvgEventNumber([27,29,63], :);
OccipitalLobe_AvgPower = AvgPower([27,29,63], :);
OccipitalLobe_peakPower = peakPower([27,29,63], :);

AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/ERPs/EdaDI.xlsx'));

addpath(('Z:/DB_SQL/'));

all_ages = db_query('select id ||''_''|| to_char(vtimestamp,''YYYYMMDD'') as IDvalues, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg''  order by id, age ');
all_ages.idvalues= char(all_ages.idvalues);

for j = 1 : length(setfiles0)
    
    idvalues(j,:) = (setfiles0(j).name(1:14));
end


OccipitalLobe_MeanAvgEventNumber = mean(OccipitalLobe_AvgEventNumber,1)';
OccipitalLobe_MeanAvgEventDuration = mean(OccipitalLobe_AvgEventDuration,1)'; 
OccipitalLobe_MeanAvgPower = mean(OccipitalLobe_AvgPower, 1)'; 
OccipitalLobe_MeanpeakPower = mean(OccipitalLobe_peakPower, 1)'; 


T = table(idvalues, OccipitalLobe_MeanAvgEventNumber, OccipitalLobe_MeanAvgEventDuration, OccipitalLobe_MeanAvgPower, OccipitalLobe_MeanpeakPower);
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/OccipitalLobe_beta_Spectral_Analysis_Table.mat'), 'T')

all_info = innerjoin(T, all_ages);


all_info = all_info(all_info.OccipitalLobe_MeanAvgEventNumber ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/OccipitalLobe_beta_Spectral_Analysis_Table_all.csv'));




% Central beta
Central_AvgEventDuration  = AvgEventDuration([8:10, 13:18, 32, 42:45, 48, 54], :);
Central_AvgEventNumber = AvgEventNumber([8:10, 13:18, 32, 42:45, 48, 54], :);
Central_AvgPower = AvgPower([8:10, 13:18, 32, 42:45, 48, 54], :);
Central_peakPower = peakPower([8:10, 13:18, 32, 42:45, 48, 54], :);

AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/ERPs/EdaDI.xlsx'));

addpath(('Z:/DB_SQL/'));

all_ages = db_query('select id ||''_''|| to_char(vtimestamp,''YYYYMMDD'') as IDvalues, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg''  order by id, age ');
all_ages.idvalues= char(all_ages.idvalues);

for j = 1 : length(setfiles0)
    
    idvalues(j,:) = (setfiles0(j).name(1:14));
end


Central_MeanAvgEventNumber = mean(Central_AvgEventNumber,1)';
Central_MeanAvgEventDuration = mean(Central_AvgEventDuration,1)'; 
Central_MeanAvgPower = mean(Central_AvgPower, 1)'; 
Central_MeanpeakPower = mean(Central_peakPower, 1)'; 


T = table(idvalues, Central_MeanAvgEventNumber, Central_MeanAvgEventDuration, Central_MeanAvgPower, Central_MeanpeakPower);
save(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Central_beta_Spectral_Analysis_Table.mat'), 'T')

all_info = innerjoin(T, all_ages);


all_info = all_info(all_info.Central_MeanAvgEventNumber ~= 0, :);

writetable(all_info, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Central_beta_Spectral_Analysis_Table_all.csv'));



