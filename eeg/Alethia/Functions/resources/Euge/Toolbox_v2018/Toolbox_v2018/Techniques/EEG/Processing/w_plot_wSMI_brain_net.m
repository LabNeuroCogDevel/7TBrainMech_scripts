function [EEG, data] = w_plot_wSMI_brain_net(conditions_1, conditions_2, configurationMat,taus, taus_values, node_file_names, methods, wsmi_path, EEG, data)
%plots files created by mainPlotwSMIStatsAndConnections - uses Brain Net
%Viewer
%WARNING: requires that BrainMesh_ICBM152.nv and configurationMat and be in a relative path of
%wSMI\BrainNetAux
if isequal(wsmi_path,'')
    wsmi_path = data.path;
end
%PARAMETERS
% root_path = 'G:\iEEG\DVT\DVT_Resting\';
node_file_names = cellstr(strsplit(node_file_names));%{'wSMI\boot\P13_NRH_DVT-P13_NRH_Resting-tau-4.node'};
local_path = fullfile(wsmi_path, 'wSMI', 'chosen');%{'wSMI\chosen\ttest_0.0000001\','wSMI\chosen\boot_0.005\'}; %OJO - son local paths que tienen que estar creados

taus = str2num(taus);%[1 2 4 8 16 32];
taus_values = str2num(taus_values);%[5 3 3 4 3];
% taus_values = [5 3 3 4 3];

conditions_1 = cellstr(strsplit(conditions_1));%{'P10_DVT','P10_DVT_256','P13_DVT','P9_DVT','P9_DVT_256'};
conditions_2 = cellstr(strsplit(conditions_2));%{'P10_Resting','P10_Resting_256','P13_Resting','P9_Resting','P9_Resting_256'};

imageExt = '.eps';
surfaceFile = fullfile(wsmi_path, 'wSMI', 'BrainNetAux', 'BrainMesh_ICBM152.nv');
configurationMat = fullfile(wsmi_path, 'wSMI', 'BrainNetAux',configurationMat);

%methods = {'ttest','boot'};
methods = cellstr(strsplit(methods));%{'boot'};
%p_vals_string = {'0.05'};

for met = 1 : size(methods,2)
    method = methods{met};   

    for cond = 1 : size(conditions_1,2)
        method_folder = fullfile(wsmi_path, 'wSMI', method);
        if ~exist(method_folder, 'dir')
          mkdir(method_folder);
        end
        fileName = fullfile(method_folder, [conditions_1{cond} '-' conditions_2{cond} '-tau-' num2str(taus(taus_values(cond)))]);
        edgefile = [fileName '.edge'];
        nodefile = fullfile(wsmi_path,'brain_net',node_file_names{cond});
        
        %OJO - son local paths que tienen que estar creados y las funciones
        %que llama son del toolbox Brain Net Viewer
        figs_folder = fullfile(method_folder, 'figs');
        if ~exist(figs_folder, 'dir')
          mkdir(figs_folder);
        end
        fileName2Save = fullfile(figs_folder, [conditions_1{cond} '-' conditions_2{cond} '-tau-' num2str(taus(taus_values(cond)))  '_nodes' imageExt]);
        BrainNet_MapCfg(surfaceFile,nodefile,edgefile,configurationMat,fileName2Save);
    end
end

display('END')