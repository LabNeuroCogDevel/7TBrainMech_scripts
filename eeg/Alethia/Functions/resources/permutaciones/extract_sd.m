function [ subj_vec_sd,baseline_vec_sd] = extract_sd(cfg);
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
EEG = pop_loadset('filename',cfg.set,'filepath',cfg.orig_dir_uno);
EEG = eeg_checkset( EEG );

subj_vec_sd = zeros(size(EEG.data,3),size(cfg.tiempos,2)+1);
subj_vec_sd(:,1) = [1:size(EEG.data,3)];

baseline_vec_sd = zeros(size(EEG.data,3),size(cfg.tiempos,2)+1);
baseline_vec_sd(:,1) = [1:size(EEG.data,3)];

if cfg.normaliza_datos ~= 1
    cfg_bl = cfg;
    cfg_bl.ventana = cfg.baseline;baseline_times = puntos_times(cfg_bl);

    for r = 2:size(cfg.tiempos,2)+1
        averageROI = mean(EEG.data([cfg.rois{1,r-1}],cfg.tiempos(r-1).puntos,:),1);
        subj_vec_sd(:,r) = squeeze(std(averageROI,0,2));
        
        averageBL_ROI = mean(EEG.data([cfg.rois{1,r-1}],baseline_times.puntos,:),1);
        baseline_vec_sd(:,r) = squeeze(std(averageBL_ROI,0,2));
    end
    
else
cfg_bl = cfg;
cfg_bl.ventana = cfg.baseline;

baseline_times = puntos_times(cfg_bl);
for r = 2:size(cfg.tiempos,2)+1
    averageBL_ROI = mean(EEG.data([cfg.rois{1,r-1}],baseline_times.puntos,:),1);
    baseline_val = squeeze(std(averageBL_ROI,0,2));
    averageROI = mean(EEG.data([cfg.rois{1,r-1}],cfg.tiempos(r-1).puntos,:),1);
    data = squeeze(std(averageROI,0,2));
    
    subj_vec_sd(:,r) = data./baseline_val;
    baseline_vec_sd(:,r) = baseline_val;
end
end
