function [ subj_vec_auc] = extract_auc_bl(cfg,subjnum_sp,FLAG);
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
EEG = pop_loadset('filename',cfg.set,'filepath',cfg.orig_dir_uno);
EEG = eeg_checkset( EEG );
cfg_bl = cfg;
cfg_bl.ventana = cfg.baseline;

baseline_times = puntos_times(cfg_bl);


subj_vec_auc = nan(size(EEG.data,3),size(cfg.tiempos,2)+1);
subj_vec_auc(:,1) = subjnum_sp;

for r = 2:size(cfg.tiempos,2)+1
    data = squeeze(mean(EEG.data([cfg.rois{1,r-1}],cfg.tiempos(r-1).puntos,:),1)); % mean([electrodos, tiempo, sujetos], eletrodos)
    baseline_val = squeeze(mean(mean(EEG.data([cfg.rois{1,r-1}],baseline_times.puntos,:),1)));
    
    for col = 1:size(data,2)
    data(:,col) = data(:,col)-baseline_val(col);
    end
    
    if strcmp(FLAG, 'up')       
        data(data<0) = 0;      
     elseif  strcmp(FLAG, 'do')
     data(data>0) = 0;      
     data = abs(data);
    else
        disp('solo acepta UP o DO como parametros');
    end
 subj_vec_auc(:,r) = squeeze(sum(data,1));

end

