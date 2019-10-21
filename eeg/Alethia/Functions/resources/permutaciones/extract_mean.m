function [ subj_vec_mean] = extract_mean(cfg,subjnum_sp);
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
EEG = pop_loadset('filename',cfg.set,'filepath',cfg.orig_dir_uno);
EEG = eeg_checkset( EEG );

subj_vec_mean = zeros(size(EEG.data,3),size(cfg.tiempos,2)+1);
subj_vec_mean(:,1) = subjnum_sp;

if cfg.normaliza_datos ~= 1
    
    for r = 2:size(cfg.tiempos,2)+1
        subj_vec_mean(:,r) = squeeze(mean(mean(EEG.data([cfg.rois{1,r-1}],cfg.tiempos(r-1).puntos,:),1),2));
    end
    
else
cfg_bl = cfg;
cfg_bl.ventana = cfg.baseline;

baseline_times = puntos_times(cfg_bl);
    for r = 2:size(cfg.tiempos,2)+1
    baseline_val = squeeze(mean(mean(EEG.data([cfg.rois{1,r-1}],baseline_times.puntos,:),1)));
    data = squeeze(mean(mean(EEG.data([cfg.rois{1,r-1}],cfg.tiempos(r-1).puntos,:),1),2));
    subj_vec_mean(:,r) = data-baseline_val;   
    end
end
