function [EEG_ERP_variables] = extract_caracteristicas_normalizado(cfg,filename_out)
% Armar tabla que tenga 
%%  Determinar valores medios, maximos, minimos y latencias por sujeto
% en suj num(length(EEG.epoch)): [sd(ROIn)]*n
% en suj num(length(EEG.epoch)): [sd(ROIn),max(ROIn),t.max(ROIn),min(ROIn),t.min(ROIn)]*n

% Asociated rou
eeglab

EEG = pop_loadset('filename',[cfg.pretag '.set'],'filepath',cfg.orig_dir_uno);
EEG = eeg_checkset( EEG );

EEG_ERP_variables = nan(length(EEG.epoch),1*length(cfg.rois)+1);

cfg.set = [cfg.pretag,'.set'];
EEG_ERP_variables =extract_sd(cfg);


%% Acomodar valores en la tabla final
col_header = {'Suj','sdR1','sdR2','sdR3','sd4','sd5'};

for col = 1:length(col_header)
col_header{col} = strcat(col_header{col},'_', filename_out);
end

data_cells=num2cell(EEG_ERP_variables);     %Convert data to cell array
for s = 1:length(EEG_ERP_variables)
row_header(s)={['s',num2str(s)]};     %Column cell array (for row labels)
end
output_matrix=[{' '} col_header; row_header' data_cells];     %Join cell arrays
xlswrite([filename_out,'ERP_Variables.xls'],output_matrix);     %Write data and both headers
