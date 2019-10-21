function [C1] = load_wSMI_connectivity_matrix(path,fileName,tau,channelNr)

direc = path;

C1 = [];

fileout= fullfile(direc,'Results','SMI',[fileName,'_CSD.mat']);
load(fileout); 

wSMI4Tau = wSMI.Trials{tau};
matrixSize = channelNr;
tempResultMatrix = nan(matrixSize);

for tr =1:size(wSMI4Tau,2)
    wSMI4TauByTrial = wSMI4Tau(:,tr);       
    n = 0;
    for i = 1:matrixSize 
        for j = (i+1):matrixSize;
            n = n + 1;
            tempResultMatrix(i,j) = wSMI4TauByTrial(n);
            tempResultMatrix(j,i) = wSMI4TauByTrial(n);
        end
    end
    C1 = cat(3,C1,tempResultMatrix);    
end

C1(isnan(C1)) = 0;
