function [bin1FINAL, bin2FINAL, bin3FINAL, bin4FINAL] = binSubjects(condition)

AgeFile = xlsread(hera('Projects/7TBrainMech/scripts/eeg/Alethia/Results/ERPs/EdaDI.xlsx'));

bin1 = find(AgeFile(:,3) >= 10 & AgeFile(:,3) <= 15); 
bin2 = find(AgeFile(:,3) >= 16 & AgeFile(:,3) <= 20); 
bin3 = find(AgeFile(:,3) >= 21 & AgeFile(:,3) <=25); 
bin4 = find(AgeFile(:,3) >= 26 & AgeFile(:,3) <=31); 

bin1Subjects = (AgeFile(bin1,2));
bin2Subjects = (AgeFile(bin2,2));
bin3Subjects = (AgeFile(bin3,2)); 
bin4Subjects = (AgeFile(bin4,2));


%% collecting bin 1 subjects: ages 10-15
for i = 1: length(bin1Subjects) 
    bin1File(i,:) = sprintf('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/PermutEpoch/%d', bin1Subjects(i));
    file = dir(hera([bin1File(i,:) '*' condition '*.set']));
    if isempty(file)
        continue;
    end
    bin1Files(i,:) = dir(hera([bin1File(i,:) '*' condition '*.set']));
    files(i,:) = fullfile(bin1Files(i,:).folder, bin1Files(i,:).name);
end
bin1_subjnum_sp = find(~cellfun(@isempty,cellstr(files)));
bin1FINAL = {bin1Files(bin1_subjnum_sp).name}; % cell array with EEG file names

%% collecting bin 2 subjects: ages 16-20
for i = 1: length(bin2Subjects) 
    bin2File(i,:) = sprintf('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/PermutEpoch/%d', bin2Subjects(i));
    file2 = dir(hera([bin2File(i,:) '*' condition '*.set']));
    if isempty(file2)
        continue;
    end
    bin2Files(i,:) = dir(hera([bin2File(i,:) '*' condition '*.set']));
    files2(i,:) = fullfile(bin2Files(i,:).folder, bin2Files(i,:).name);

end    

bin2_subjnum_sp =find(~cellfun(@isempty,cellstr(files2)));
bin2FINAL = {bin2Files(bin2_subjnum_sp).name}; % cell array with EEG file names

%% collecting bin 3 subjects: ages 21-25
for i = 1: length(bin3Subjects) 
    bin3File(i,:) = sprintf('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/PermutEpoch/%d', bin3Subjects(i));
    file3 = dir(hera([bin3File(i,:) '*' condition '*.set']));
    if isempty(file3)
        continue;
    end
    bin3Files(i,:) = dir(hera([bin3File(i,:) '*' condition '*.set']));
    files3(i,:) = fullfile(bin3Files(i,:).folder, bin3Files(i,:).name);

end    

bin3_subjnum_sp =find(~cellfun(@isempty,cellstr(files3)));
bin3FINAL = {bin3Files(bin3_subjnum_sp).name}; % cell array with EEG file names

%% collecting bin 4 subjects: ages 26-31
for i = 1: length(bin4Subjects) 
    bin4File(i,:) = sprintf('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/PermutEpoch/%d', bin4Subjects(i));
   file4 = dir(hera([bin4File(i,:) '*' condition '*.set']));
    if isempty(file4)
        continue;
    end
    bin4Files(i,:) = dir(hera([bin4File(i,:) '*' condition '*.set']));
    files4(i,:) = fullfile(bin4Files(i,:).folder, bin4Files(i,:).name);

end    

bin4_subjnum_sp =find(~cellfun(@isempty,cellstr(files4)));
bin4FINAL = {bin4Files(bin4_subjnum_sp).name}; % cell array with EEG file names


end 




