function plot_wSMI_stats_and_connections(wsmi_path,condition1,condition2,channel_nr,tau,p_value,method,plot_stats_aux,threshold,electrodes,color_positive,color_negative,node_spec,new_file_name)
%Loads connectivity matrices for two conditions and performs a statistical
%comparison between them. Then plots the significant connections in 3D.
%Optionally plots histograms of statistical data and matrices.
%INPUTS:
%wsmi_path: localpath were wsmi connectivity matrices are stored
%condition1: name of condition 1 - used as part of file name of
%                   connectivity matrix - OJO- si calculamos un solo archivo de conectividad
%                   deberiamos elegir las condiciones (los trials que se corresponden a esa
%                   condicion)
%condition2: name of condition 2 - used as part of file name of
%                   connectivity matrix - OJO- si calculamos un solo archivo de conectividad
%                   deberiamos elegir las condiciones (los trials que se corresponden a esa
%                   condicion)
%channel_nr: number of channels in matrix
%tau: tau value to consider
%p_value: value to be considered as statistically significant
%method: string - statistical method to use. Possible values: boot, perm
%               and ttest
%plot_stats_aux: plots auxiliary figures of statistical data (histrograms
%                       and connectivity matrices) if value = 1
%threshold: T value threshold to be considered of statistical values
%                 obtained- Tmax = threshold, Tmin = -threshold
%electrodes: struct with electrodes coodinates for 3D plot - x,y,z
%                   attributes
%color_positive: rgb vector for condition 1 - that is, positive T values
%color_negative: rgb vector for condition 2 - that is, negative T values
%node_spec: struct with node coloring specifications:
%           attributes:
%               condition: 'default' for connected links; 'other' for
%                                           nodes that do not present
%                                           connections
%           	size: node size
%               color: node color
%new_file_name: file name used to save created plots

node_spec(1).condition = 'default';
node_spec(1).size = '1';
node_spec(1).color = '1';

node_spec(2).condition = 'other';
node_spec(2).size = '2';
node_spec(2).color = '';

[tsignificantMat,t,p] = wSMI_stats(wsmi_path,condition1,condition2,tau,channel_nr,method,p_value);

%plot matrix of  T values and histograms
if plot_stats_aux == 1
    plot_conn_matrix_statistical_graphs(p,t,p_value,threshold,electrodes.labels,new_file_name)
end

%plot values above threshold on 3D head plot
stat_head_plot_for_two_conditions(tsignificantMat,threshold,color_positive,color_negative,electrodes,node_spec,new_file_name)
