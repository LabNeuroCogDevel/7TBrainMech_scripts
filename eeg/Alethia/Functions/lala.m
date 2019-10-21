
xlswrite('Data_Removed',channels_removed(1,:)')

%to save names of channels 
for i = 1:length(channels_removed)
    NameCell = channels_removed{2,i}; 
        if isempty(NameCell) == 1 
            continue
        end
    allCell = cellstr(strjoin(NameCell()));
    Value = length(NameCell); 
    loc2 = sprintf('D%d', i); 
    xlswrite('Data_Removed', Value, 1, loc2); 
    loc = sprintf('B%d',i); 
    xlswrite('Data_Removed', allCell, 1, loc);
end


%to save the channel numbers 
for j = 1:length(channels_removed)
    NumberCell = int2str(channels_removed{3,j}'); 
      if isempty(NumberCell) == 1 
            continue
        end
    allCell = cellstr(strjoin(cellstr(NumberCell())));
    loc = sprintf('C%d',j); 
    xlswrite('Data_Removed', allCell, 1, loc);
end

%save epochs removed
xlswrite('Data_Removed',epochs_removed(2:3,:)', 1, 'E2'); 


%save data removed
xlswrite('Data_Removed',data_removed(2:3,:)', 1, 'G2'); 

%% save components removed
cd('H:\Projects\7TBrainMech\scripts\eeg\Alethia\Prep_100\AfterWhole/ICAwholeClean')
subjectList = dir('*_pesos.set');

% Import the file
subjects = {subjectList.name}; 

components = cell(76,1);
name = cell(76,1);
saveComponents = zeros(76,63);



for i = 1:length(subjectList)
    subject = string(subjects(:,i));
    
    fileToRead1 = sprintf('/Projects/7TBrainMech/scripts/eeg/Alethia/Prep_100/AfterWhole/ICAwholeClean/%s', subject);
    newData1 = importdata(fileToRead1);
    
    % Create new variables in the base workspace from those fields.
    vars = fieldnames(newData1);
    for j = 1:length(vars)
        assignin('base', vars{j}, newData1.(vars{j}));
    end
    
    components(i,:) = num2cell(strjoin(string((find(reject.gcompreject)))));
    
%     %Create Struct with components
%     name(i,:) = cellstr(strjoin(cellstr(int2str(sscanf(subject, '%d_%d')))))';
% 
%     if size(reject.gcompreject,2) ~= 63
%        reject.gcompreject(numel((saveComponents(1,:))))=0;
%     end
%     saveComponents(i,:) = (reject.gcompreject); 
%     
    
end

cd('H:\Projects\7TBrainMech\scripts\eeg\Alethia\Functions');
xlswrite('Data_Removed',components, 1, 'I2'); 


%% save old components to new files
eeglab
cd('H:\Projects\7TBrainMech\scripts\eeg\Alethia\Prep_100\AfterWhole/ICAwholeClean')
oldsubjectList = dir('*_pesos.set');

% Import the file
oldsubjects = {oldsubjectList.name}; 
for i = 1:length(oldsubjectList)
    
    oldsubject = string(oldsubjects(:,i));
    %load in old version
    fileToRead1 = sprintf('/Projects/7TBrainMech/scripts/eeg/Alethia/Prep_100/AfterWhole/ICAwholeClean/%s', oldsubject);
    
    oldEEG = importdata(hera(fileToRead1));
    
    oldComponents(:,i) = oldEEG.reject.gcompreject;
    
end

    %load in new version
    cd('H:\Projects\7TBrainMech\scripts\eeg\Alethia\Prep\ICAwhole')
    subjectList = dir('*.set');

% Import the file
subjects = {subjectList.name}; 

for i = 1:length(subjectList)
    
    subject = string(subjects(:,i));
    
    NewfileToRead1 = sprintf('/Projects/7TBrainMech/scripts/eeg/Alethia/Prep/ICAwhole/%s', subject);
    newEEG = pop_loadset('filename',NewfileToRead1);
    
    newEEG.reject.gcompreject = oldComponents;
    
    path_data = hera('Projects\7TBrainMech\scripts\eeg\Alethia\Prep\ICAwhole\');
    EEGfileNames = dir([path_data, '/*.set']);
    filename = EEGfileNames(i).name;
    
    CleanICApath = hera('Projects\7TBrainMech\scripts\eeg\Alethia\Prep\AfterWhole\ICAwholeClean\');

   cd(CleanICApath);
pop_saveset( newEEG, 'filename',[filename(1:end-4),'_pesos.set'],'filepath',CleanICApath);
    
end

   
    
    




