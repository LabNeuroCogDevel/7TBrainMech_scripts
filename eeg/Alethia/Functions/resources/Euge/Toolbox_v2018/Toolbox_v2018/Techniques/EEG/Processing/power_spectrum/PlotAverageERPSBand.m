function PlotAverageERPSBand(mat1,mat2,timesout,statmethod,p_value,prefixFileName,titleName,color1,color2,colorPvalue)
%Calculates and plots the mean ERPS for two conditions and its statistical
%analysis. Input matrices MUST contain the desired frequency band in the
%first dimension (this method does not select frequency values).

% INPUTS:
% * mat1: 3D (frequency x time x trials) mat for condition 1
% * mat2: 3D (frequency x time x trials) mat for condition 2
% * timesout: vector with time values of calculated time-frequency maps
% * statmethod: string of the statistical method to be used (possible values: boot or
% ranksum)
% * p_value: threshold of statistical significance (e.g. p = 0.05)
% prefixFileName: string that will be appended to titleName as the filename
% that will be saved (possibly the path)
% titleName: title for plot
% color1: color of plot for condition 1
% color2: color of plot for condition 2
% colorPvalue: color of plot for significant points (those below p_value)

%mean frequency 
mean1 = squeeze(mean(mat1,1));
mean2 = squeeze(mean(mat2,1));

h = figure;
[h1 maxcond1] = plot_std_met(mean1,timesout, color1);  
hold on
[h2 maxcond2] = plot_std_met(mean2,timesout, color2); 

%legend([h1,h2],{conditionName1,conditionName2},'Location','Best')

titleName = [titleName '-' statmethod];
title(titleName)
ylabel('mean ERPS(std.)')
set(gca,'box','off')

p1 = permute(mat1,[2 3 1]);
r1 = reshape(p1,length(timesout),size(mat1,3)*size(mat1,1));

p2 = permute(mat2,[2 3 1]);
r2 = reshape(p2,length(timesout),size(mat2,3)*size(mat2,1));

Permut{1} = r1; % transform variables to cellarray
Permut{2} = r2; % transform variables to cellarray

if strcmp(statmethod,'boot')
    [t df pvals] = statcond(Permut, 'mode', 'bootstrap','paired','off','tail','both','naccu',1000);   %calcula permutaciones
    %[t df pvals] = statcond(Permut, 'mode', 'perm','paired','off','tail','both','naccu',1000);   %calcula permutaciones       
    [i_ind y]=find(pvals<p_value);
    
else
    [pvals h zval ranksum] = ranksumForMatrices(rINT,rACC,p_value);
    [i_ind y]=find(pvals<p_value);
end

if ~isempty(i_ind)
    zero_index = interp1(timesout,1:length(timesout),0);
    i_ind = i_ind(i_ind < zero_index); %harcoded index for cero - baseline is not included
    
    max_cond = max([maxcond1 maxcond2]);        
    plot(timesout(i_ind),max_cond*1.1,'*', 'Color',colorPvalue, 'MarkerSize', 5)
end

xlabel('Time (ms)')
set(gca,'box','off')
set(gcf,'color','w')
title(titleName)

saveas(gcf,[prefixFileName titleName],'fig');
saveas(gcf,[prefixFileName titleName],'eps');
saveas(gcf,[prefixFileName titleName],'png');