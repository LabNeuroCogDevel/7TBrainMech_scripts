function [EEG_HEP_variables] = extract_caracteristicas_sinormalizar(cfg,grupo,filtro,filename_out)
% Armar tabla que tenga 
%%  Determinar valores medios, maximos, minimos y latencias por sujeto
% en suj num(1-160): [mean(ROIn),max(ROIn),t.max(ROIn),min(ROIn),t.min(ROIn)]*n
% Asociated rou

grup{1} = 'PBCs';
grup{2} = 'CC';
grup{3} = 'CTR';

EEG_HEP_variables = nan(160,1*length(cfg.rois)+1);

for j = 1:length(grup)
    if strcmp(grup{j} , 'PBCs')
        Gru=1 ;% specify group name (as presented in folder)
%         cfg.set = 'PBCs_post_rej.set';
        cfg.set = ['PBCs',cfg.pretag,'_rej.set'];

    elseif strcmp(grup{j} , 'CC')
        Gru=5 ;% specify group name (as presented in folder)
%         cfg.set = 'CC_post_rej.set';
         cfg.set = ['CC',cfg.pretag,'_rej.set'];

    elseif strcmp(grup{j} , 'CTR')
        Gru=4 ;% specify group name (as presented in folder)
%         cfg.set = 'CTR_post_rej.set';
        cfg.set =[ 'CTR',cfg.pretag,'_rej.set'];

    else
    end
    subjnum_sp = find((grupo.*filtro)== Gru);
    
    subj_vec = [];
    
    % variable 1
    subj_vec_mean = extract_mean(cfg,subjnum_sp);
    
%      % variable 2 y 3
%     [subj_vec_max,subj_vec_maxRT]= extract_extreme(cfg,subjnum_sp,'up');
%     
%     % variable 4 y 5
%     [subj_vec_min,subj_vec_minRT]= extract_extreme(cfg,subjnum_sp,'do');
%     
% %     % variable 6 y 7
% %     [subj_vec_auc_pos]= extract_auc(cfg,subjnum_sp,'up');
% %     [subj_vec_auc_neg]= extract_auc(cfg,subjnum_sp,'do');
% % 
% %     % variable 8
% %     subj_vec_auc_tot = subj_vec_auc_pos + subj_vec_auc_neg;
%     
%     % variable 9 y 10
%     [subj_vec_auc_pos_bl]= extract_auc_bl(cfg,subjnum_sp,'up');
%     [subj_vec_auc_neg_bl]= extract_auc_bl(cfg,subjnum_sp,'do');
% 
%     % variable 11
%     subj_vec_auc_tot_bl = subj_vec_auc_pos_bl + subj_vec_auc_neg_bl;
    
    %% Acomodar valores en la tabla final
    EEG_HEP_variables(subjnum_sp,:) = [subj_vec_mean];%, ...
%         subj_vec_max(:,2:end),subj_vec_maxRT(:,2:end),...
%         subj_vec_min(:,2:end),subj_vec_minRT(:,2:end),...
%         subj_vec_auc_pos_bl(:,2:end),subj_vec_auc_neg_bl(:,2:end),subj_vec_auc_tot_bl(:,2:end)];
 %         subj_vec_auc_pos(:,2:end),subj_vec_auc_neg(:,2:end),subj_vec_auc_tot(:,2:end),...
   
end

col_header = {'Suj',...
     'meanR1','meanR2','meanR3','meanR4'  };%,...
%     'maxR1','maxR2','maxR3','maxR4',...
%     'maxRTR1','maxRTR2','maxRTR3','maxRTR4',...
%     'minR1','minR2','minR3','minR4',...
%     'minRTR1','minRTR2','minRTR3','minRTR4',...
%     'auc_pos_blR1','auc_pos_blR2','auc_pos_blR3','auc_pos_blR4',...
%     'auc_neg_blR1','auc_neg_blR2','auc_neg_blR3','auc_neg_blR4',...
%     'auc_tot_blR1','auc_tot_blR2','auc_tot_blR3','auc_tot_blR4'
%     %     'auc_posR1','auc_posR2','auc_posR3','auc_posR4',...
%     'auc_negR1','auc_negR2','auc_negR3','auc_negR4',...
%     'auc_totR1','auc_totR2','auc_totR3','auc_totR4',... 
  

for col = 1:length(col_header)
col_header{col} = strcat(col_header{col},'_', filename_out);
end

data=EEG_HEP_variables;     %Sample 2-dimensional data
data_cells=num2cell(data);     %Convert data to cell array
for s = 1:length(EEG_HEP_variables)
row_header(s)={['s',num2str(s)]};     %Column cell array (for row labels)
end
output_matrix=[{' '} col_header; row_header' data_cells];     %Join cell arrays
xlswrite([filename_out,'HEP_Variables.xls'],output_matrix);     %Write data and both headers
