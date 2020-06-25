
function [] = check_if_exists()


EEGfileNames = dir([path_data '/*.set']);
outEEGfileNamesStruct = dir([CleanICApath '/*icapru.set']);

for i = 1: length(EEGfileNames)
    AllEEGfileNames{i} = [EEGfileNames(i).folder '/' EEGfileNames(i).name];
    
end

for i = 1: length(outEEGfileNamesStruct)
    outEEGfileNames{i} = [outEEGfileNamesStruct(i).folder '/' outEEGfileNamesStruct(i).name];
    
end

outputFileNames = num2cell(zeros(size(AllEEGfileNames)));
outputFileNames(:,1:length(outEEGfileNames)) = outEEGfileNames;


for currentEEG = 1:size(EEGfileNames,1)
    xEEG = 1;
    outFilename = outputFileNames(currentEEG);
    filename = [EEGfileNames(currentEEG).name];
    
    inputfile = ([EEGfileNames(currentEEG).folder '/' filename ]);
    outputfile = string(outFilename);
    
    if xEEG == 1
        xEEG = load_if_exists(outputfile);
    end
    
    if isstruct(xEEG)
        [ALLEEG EEG CURRENTSET] = pop_newset([], xEEG, 0)
    else
        