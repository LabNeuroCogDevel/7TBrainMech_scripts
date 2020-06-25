function [idx1, Ages, IDvalues] = findAges(setfiles0, setfiles)



AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/ERPs/EdaDI.xlsx'));

% all_ages = db_query('select id, age, visitno from visit natural join enroll where etype like ''LunaID''  and vtype ilike ''eeg'' and visitno < 2 order by id, age ');


for j = 1 : length(setfiles0)
    
    IDvalues(j) = str2double((setfiles0(j).name(1:5)));

end

[idx1] = ismember(AgeFile(:,2), IDvalues); 

Ages = AgeFile(idx1,2:3);
