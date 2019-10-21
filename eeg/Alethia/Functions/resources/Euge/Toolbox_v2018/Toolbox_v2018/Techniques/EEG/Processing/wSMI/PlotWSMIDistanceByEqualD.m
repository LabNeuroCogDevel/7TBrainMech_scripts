function PlotWSMIDistanceByEqualD(Task,condition1,condition2,tau,path,fileName,channelNr,electrodeDistances,p_value,distanceThresholdPlot,fileName2save)
%plot average wSMI connectivity by distance - consider equal length steps
%and calculates an average
%distances
%INPUT:
%Task: task name to append in title of plots
%condition1: name of condition 1 - OJO - either filename to wsmi calculated connectivity
%                   matrices or condition name to filter from one connectivity matrix
%condition2: name of condition 2 - OJO - either filename to wsmi calculated connectivity
%                   matrices or condition name to filter from one connectivity matrix
%tau: tau value to load
%path: relative path to wsmi connectivity matrices
%fileName: string - common prefix to file names of connectivity matrices of
%               two conditions - OJO si se levanta un archivo y luego se filtra por
%               condicion habria que cambiar el codigo
%channelNr: number of channels
%electrodeDistances: symmetric matrix of distances between each electrode
%                   pair
%p_value: threshold for statistical comparison
% distanceThresholdPlot: value different to 0 if distances above a certain
%                                       threshold should be considered
%fileName2save: string that will be used as the file that will be saved
%OUTPUT:
%plots of wsmi connectivity by distance for two conditions and the
%statistical comparison between them. Saves two files (.jpg, .fig)

direc = path;
%levanto las matrices de cada condicion
cond = {condition1,condition2};
C1 = [];C2 =[];
if ~(isequal(fileName,'') || isempty(fileName))
        fileName = [fileName '_'];
end
for c = 1:2
    
    fileout= fullfile(direc,'Results','SMI',[fileName, cond{c},'_CSD.mat']);
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
        if c == 1
            C1 = cat(3,C1,tempResultMatrix);
        else
            C2 = cat(3,C2,tempResultMatrix);
        end
    end
end

M.C1 = C1;
M.C2 = C2;

C_1 = C1;
C_2 = C2;
C_1(isnan(C_1)) = 0;
C_2(isnan(C_2)) = 0;
for i = 1:size(C1,3)
C_1(:,:,i) = triu(C_1(:,:,i)) - tril(ones(size(C_1(:,:,i)))).*2;
C_2(:,:,i) = triu(C_2(:,:,i)) - tril(ones(size(C_2(:,:,i)))).*2;
end



%en C_1 y C_2 tengo una matriz de channelNr*channelNr*trials para cada
%condicion

%me quedo con el triangulo superior de las distancias
triu_electrodeDistances=triu(electrodeDistances) - tril(ones(size(electrodeDistances))).*2;
%me quedo con los valores diferentes a cero de las distancias
%me queda un vector
triu_electrodeDistances=triu_electrodeDistances(triu_electrodeDistances~=-2);

%mean entre canales
%reshape primero
%matriz de dos dimensiones: chan*chan, trials
C_1r = reshape(C_1,channelNr*channelNr,size(C_1,3));
C_2r = reshape(C_2,channelNr*channelNr,size(C_2,3));

%promedio de valor de conectividad por canal
mean_cond1_xChannel=nanmean(C_1r,2);
mean_cond2_xChannel=nanmean(C_2r,2);

%hago un reshape para que me queden matrices cuadradas
%(channelNr*channelNr)
mean_cond1_matrix=reshape(mean_cond1_xChannel, channelNr,channelNr);
triu_mean_cond1=triu(mean_cond1_matrix);
mean_cond2_matrix=reshape(mean_cond2_xChannel, channelNr,channelNr);
triu_mean_cond2=triu(mean_cond2_matrix);

%me quedo con los valores del triangulo superior de la matriz cuadrada
pre_data_cond1=mean_cond1_matrix(triu_mean_cond1~=-2);
%armo una matriz que tiene dos columnas: los valores medios de conectividad
%y las distancias
data_cond1=cat(2,pre_data_cond1', triu_electrodeDistances'); %agrego columna de distancia
%ordeno los valores por las distancias
data_cond1_ordered=sortrows(data_cond1, 2); % sort por distancia

%me quedo con los valores del triangulo superior de la matriz cuadrada
pre_data_cond2=mean_cond2_matrix(triu_mean_cond2~=-2);
%armo una matriz que tiene dos columnas: los valores medios de conectividad
%y las distancias
data_cond2=cat(2, pre_data_cond2', triu_electrodeDistances');
%ordeno los valores por las distancias
data_cond2_ordered=sortrows(data_cond2,2);

%ACA DEBERIA HACER UN RESHAPE PARA TENER EN MI PRIMERA DIMENSION LOS TRIALS
t_C1 = permute(C_1,[3 1 2]);
t_C2 = permute(C_2,[3 1 2]);
t_C1(isnan(t_C1))=0;
t_C2(isnan(t_C2))=0;

%ME QUEDO CON EL TRIANGULO SUPERIOR PARA CADA SUJETO - EN MI CASO PARA CADA
%TRIAL

%triangulo las matrices de cada trial
for i = 1 : size(t_C1,1) %CANTIDAD DE SUJETOS
    t_C1(i,:,:) = triu(squeeze(t_C1(i,:,:)));
end

for i = 1 : size(t_C2,1)
    t_C2(i,:,:) = triu(squeeze(t_C2(i,:,:)));
end

%ARMO UNA MATRIZ DE DIMENSION CHAN*CHAN/2-CHAN/2,CANT. SUJ/TRIALS
Data_Cond1 = zeros((channelNr*channelNr/2)-(channelNr/2),size(C_1,3));
Data_Cond2 = zeros((channelNr*channelNr/2)-(channelNr/2),size(C_2,3));

for i = 1 : size(C_1,3)
    A = squeeze(t_C1(i,:,:));
    B = A(A~=-2);
    Data_Cond1(:,i) = B;
end

for i = 1 : size(C_2,3)
    A = squeeze(t_C2(i,:,:));
    B = A(A~=-2);
    Data_Cond2(:,i) = B;
end
 
% Calcula Estadística
uniqueDistances = unique(triu_electrodeDistances);
cond1UniqueValues = zeros(size(uniqueDistances,1),1);
cond2UniqueValues = zeros(size(uniqueDistances,1),1);
pvalsUniqueValues = zeros(size(uniqueDistances,1),1);

for i = 1 : size(uniqueDistances,1)
    distance = uniqueDistances(i);
    condIndexes1 = find(data_cond1(:,2)== distance);
    condIndexes2 = find(data_cond2(:,2)== distance);
   
    valuesForDistance1 = Data_Cond1(condIndexes1,:);    
    rvaluesForDistance1 = reshape(valuesForDistance1,size(valuesForDistance1,1)*size(valuesForDistance1,2),1);
    valuesForDistance = data_cond1_ordered(data_cond1_ordered(:,2)== distance);    
    meanValueForDistance = mean(valuesForDistance);
    cond1UniqueValues(i) = meanValueForDistance;
            
    valuesForDistance2 = Data_Cond2(condIndexes2,:); 
    rvaluesForDistance2 = reshape(valuesForDistance2,size(valuesForDistance2,1)*size(valuesForDistance2,2),1);
    valuesForDistance = data_cond2_ordered(data_cond2_ordered(:,2)== distance);    
    meanValueForDistance = mean(valuesForDistance);
    cond2UniqueValues(i) = meanValueForDistance;

    data = {rvaluesForDistance1',rvaluesForDistance2'};
    [t df pvals] = statcond(data, 'mode', 'perm', 'naccu', 1000,'paired','off');
    
    pvalsUniqueValues(i) = pvals;
end

Pvals_result_ordered = cat(2, pvalsUniqueValues, uniqueDistances);
Pvals_result_ordered(Pvals_result_ordered(:,1)>p_value)=0;

[i_ind]=find(Pvals_result_ordered(:,1)~=0);

if distanceThresholdPlot == 0
    distanceThresholdPlot = 1;
else    
    distanceThresholdPlot = find(Pvals_result_ordered(:,2) >= distanceThresholdPlot,1);
end

maxCond1 = max(smooth(cond1UniqueValues(distanceThresholdPlot:end),80));
maxCond2 = max(smooth(cond2UniqueValues(distanceThresholdPlot:end),80));

minCond1 = min(smooth(cond1UniqueValues(distanceThresholdPlot:end),80));
minCond2 = min(smooth(cond2UniqueValues(distanceThresholdPlot:end),80));

maxVal = max(maxCond1,maxCond2);
minVal = min(minCond1,minCond2);

f2=figure;
plot(uniqueDistances(distanceThresholdPlot:end), smooth(cond1UniqueValues(distanceThresholdPlot:end),80),'r')
hold on
plot(uniqueDistances(distanceThresholdPlot:end), smooth(cond2UniqueValues(distanceThresholdPlot:end),80), 'b')
hold on
if ~isempty(i_ind )    
    i_ind = i_ind(i_ind >= distanceThresholdPlot);
    plot(uniqueDistances(i_ind), maxVal*1.01 , '*', 'Color', 'k', 'MarkerSize', 5)
end
title(['Tau= ' num2str(tau) ' - ' Task])
ylim([minVal*1.01 maxVal*1.06])

saveas(gcf,fileName2save,'fig');
saveas(gcf,fileName2save,'png');
