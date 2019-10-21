function plot_conn_matrix_statistical_graphs(P,T,p_value,threshold,labels,base_file_name)

Tmin = -1*threshold;
Tmax = threshold;

T_signif = P;
T_signif(P>p_value)=0; 
T_signif(P<=p_value)=1; 

Tmask = T;
Tmask(Tmask>Tmin&Tmask<Tmax)=0;

signifMask = Tmask.*T_signif;
signifVals = T.*T_signif;
ResultMatrix = signifMask;

caxisValues = [Tmin Tmax];
PfileName = [base_file_name '_Tsignificancemask'];
%PlotMap(signifMask,labels,caxisValues,PfileName); 
plot_formatted_map(signifMask,labels,caxisValues,'jet',PfileName,PfileName,1); 

caxisValues = [Tmin Tmax];
PfileName = [base_file_name '_TsignificancemaskCOMPLETE'];
%PlotMap(signifMask,labels,caxisValues,PfileName); 
plot_formatted_map(signifVals,labels,caxisValues,'jet',PfileName,PfileName,1); 

%plot histogram of significant values
signifValsT = T.*T_signif;
signifVals = signifValsT(signifValsT ~= 0);
figure, hist(signifVals,100);
title([base_file_name 'Signif'])

%plot histogram
figure, hist(T(:),100);
box off
name = [base_file_name '_histogram'];

title(base_file_name)

saveas(gcf,name,'png');
saveas(gcf,name,'fig');