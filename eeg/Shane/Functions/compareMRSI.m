function [] = compareMRSI();

MRSIdata = readtable('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/txt/subj_label_val_gm_24specs_20191102.csv');

roiLabel = string(table2cell(MRSIdata(:,66))); 
MRSIsubjects = string(table2cell(MRSIdata(:,2)));
MRSIgaba = string(table2cell(MRSIdata(:,15)));
MRSIglu = string(table2cell(MRSIdata(:,24)));

row = find(roiLabel == 'L DLPFC');

dlpfc_subjects = MRSIsubjects(row);
dlpfc_gaba = MRSIgaba(row);
dlpfc_glu = MRSIglu(row);

for i = 1:length(dlpfc_subjects)
    sub = dlpfc_subjects{i};
    subid = sub(1:5); 
    dlpfc_subjects{i} = subid;
end

MRSIarray = [dlpfc_subjects dlpfc_gaba dlpfc_glu];
MRSItable = table(MRSIarray(:,1), MRSIarray(:,2) ,MRSIarray(:,3)); 
MRSItable.Properties.VariableNames{1} = 'Subject';
MRSItable.Properties.VariableNames{2} = 'GABA';
MRSItable.Properties.VariableNames{3} = 'Glu';

writetable(MRSItable, 'MRSItable.csv');


