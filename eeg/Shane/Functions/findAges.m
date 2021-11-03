function [idx1, Ages, IDvalues] = findAges(setfiles0, setfiles)

addpath('/Volumes/Zeus/DB_SQL/')

all_ages = db_query("select id || '_' || to_char(vtimestamp,'YYYYMMDD') ld8, age, visitno, vtype from visit natural join visit_study natural join enroll where etype like 'LunaID' and study like 'Brain%' and vtype like 'eeg'");

all_ages = all_ages(:, 1:3);
all_ages.Properties.VariableNames = {'Subject', 'age', 'visitno'}; 

all_ages = (table2cell(all_ages));
all_ages(:,4) = {[]};

for j = 1:size(all_ages,1)
    
    if cell2mat(all_ages(j,2)) >= 10 && cell2mat(all_ages(j,2)) <= 15
        all_ages(j,4) = {1};
    
    elseif cell2mat(all_ages(j,2)) > 15 && cell2mat(all_ages(j,2)) <= 20
        all_ages(j,4) = {2};
        
    elseif cell2mat(all_ages(j,2)) > 20 && cell2mat(all_ages(j,2)) <= 25
        all_ages(j,4) = {3}; 
        
    else cell2mat(all_ages(j,2)) > 25
        all_ages(j,4) = {4}; 
        
    end
    
end

all_ages_table = cell2table(all_ages);
all_ages_table.Properties.VariableNames = {'Subject', 'age', 'visitno', 'Group'}; 

writetable(all_ages_table, 'H:\Projects\7TBrainMech\scripts\eeg\Shane\Results\Power_Analysis\Spectral_events_analysis\agefile_20210204.csv')


