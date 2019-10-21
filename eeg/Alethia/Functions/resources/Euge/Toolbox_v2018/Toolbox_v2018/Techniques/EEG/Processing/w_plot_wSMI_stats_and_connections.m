function [EEG, data] = w_plot_wSMI_stats_and_connections(conditions_1, conditions_2, taus, taus_values, node_file_names, methods, wsmi_path, p_value, threshold, plot_stats_aux, EEG, data)
% Performs statistical comparisons between several pair of conditions of WSMI
% connectivity matrices and plots significant connectivity links.
if isequal(wsmi_path,'')
    wsmi_path = data.path;
end

taus = str2num(taus);%[1 2 4 8 16 32];
taus_values = str2num(taus_values);%[3];

%CONDITIONS NAMES OF WSMI CONNECTIVITY MATRICES
%OJO - these two vectors must have the same length
conditions_1 = cellstr(strsplit(conditions_1));%{'P10_DVT','P10_DVT_256','P13_DVT','P9_DVT','P9_DVT_256'};
conditions_2 = cellstr(strsplit(conditions_2));%{'P10_Resting','P10_Resting_256','P13_Resting','P9_Resting','P9_Resting_256'};

% channel_numbers = [70];

%must have same length as conditions
node_file_names = cellstr(strsplit(node_file_names));%{'wSMI\BrainNetAux\RepossiniRestingNodes.node','wSMI\BrainNetAux\RepossiniRestingNodes.node','wSMI\BrainNetAux\MiliaRestingNodes.node','wSMI\BrainNetAux\FarinelliRestingNodes.node','wSMI\BrainNetAux\FarinelliRestingNodes.node'};

%methods = {'ttest','boot','perm'};
methods = cellstr(strsplit(methods));%{'boot'};

%wSMI mat info
% wsmi_path = '';

%statistics
p_value = str2num(p_value);%0.05;
threshold = str2num(threshold);%1;
plot_stats_aux = str2num(plot_stats_aux);%1; %0-> do NOT plot; 1-> do PLOT

%plot information
color_positive = [1 0 0]; %RED -> condition1
color_negative = [0 0 1]; %BLUE -> condition2

node_spec(1).condition = 'default';
node_spec(1).size = '1';
node_spec(1).color = '1';

node_spec(2).condition = 'other';
node_spec(2).size = '2';
node_spec(2).color = '';

for cond = 1 : size(conditions_1,2)
    condition1 = conditions_1{cond};
    condition2 = conditions_2{cond};
%     channel_nr = channel_numbers(cond);
    tau = taus_values(cond);
    %electrodes
    node_file_name = fullfile(data.path, 'brain_net', node_file_names{cond});
    electrodes = load_electrodes_from_node(node_file_name);
    channel_nr = length(electrodes.x);
    for met = 1 : size(methods,2)
        method = methods{met};
        %OJO - ARMO ESTE PATH RELATIVO AL PROYECTO PARA GUARDAR LOS PLOTS
        %QUE SE GENERAN - TENDRIA QUE CREAR EL PATH SI NO EXISTE
        %file name to save
        folder = fullfile(data.path, 'wSMI', method);
        if ~exist(folder, 'dir')
          mkdir(folder);
        end
        new_file_name = fullfile(folder, [condition1 '-' condition2 '-tau-' int2str(taus(1,tau))]);
        
        plot_wSMI_stats_and_connections(wsmi_path,condition1,condition2,channel_nr,tau,p_value,method,plot_stats_aux,threshold,electrodes,color_positive,color_negative,node_spec,new_file_name)
    end
end

display('DONE')