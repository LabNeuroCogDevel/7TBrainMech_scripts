function [ subj_vec_auc] = extract_auc(cfg,subjnum_sp,FLAG);
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
EEG = pop_loadset('filename',cfg.set,'filepath',cfg.orig_dir_uno);
EEG = eeg_checkset( EEG );

subj_vec_auc = zeros(size(EEG.data,3),size(cfg.tiempos,2)+1);
subj_vec_auc(:,1) = subjnum_sp;

for r = 2:size(cfg.tiempos,2)+1
    data = squeeze(mean(EEG.data([cfg.rois{1,r-1}],cfg.tiempos(r-1).puntos,:),1)); % mean([electrodos, tiempo, sujetos], eletrodos)
    
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


