function [subj_vec_m,subj_vec_mRT]= extract_extreme(cfg,subjnum_sp,flag)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

EEG = pop_loadset('filename',cfg.set,'filepath',cfg.orig_dir_uno);
EEG = eeg_checkset( EEG );

subj_vec_m = zeros(size(EEG.data,3),size(cfg.tiempos,2)+1);
subj_vec_mRT = zeros(size(EEG.data,3),size(cfg.tiempos,2)+1);

subj_vec_m(:,1) = subjnum_sp;
subj_vec_mRT(:,1) = subjnum_sp;


if cfg.normaliza_datos ~= 1
    
    if strcmp(flag, 'up')
        
        for r = 2:size(cfg.tiempos,2)+1
            [subj_vec_m(:,r), tiempo_m] = max(squeeze(mean(EEG.data([cfg.rois{1,r-1}],cfg.tiempos(r-1).puntos,:),1)));
            for s = 1 : length(tiempo_m)
                subj_vec_mRT(s,r) = cfg.tiempos(r-1).tiempos(tiempo_m(s));
            end
            
        end
        
    elseif strcmp(flag, 'do')
        for r = 2:size(cfg.tiempos,2)+1
            [subj_vec_m(:,r), tiempo_m] = min(squeeze(mean(EEG.data([cfg.rois{1,r-1}],cfg.tiempos(r-1).puntos,:),1)));
            for s = 1 : length(tiempo_m)
                subj_vec_mRT(s,r) = cfg.tiempos(r-1).tiempos(tiempo_m(s));
            end
            
        end
        
    end
else
    
    cfg_bl = cfg;
    cfg_bl.ventana = cfg.baseline;
    
    baseline_times = puntos_times(cfg_bl);
    
    if strcmp(flag, 'up')
        
        for r = 2:size(cfg.tiempos,2)+1
            baseline_val = squeeze(mean(mean(EEG.data([cfg.rois{1,r-1}],baseline_times.puntos,:),1)));
            [subj_vec_m(:,r), tiempo_m] = max(squeeze(mean(EEG.data([cfg.rois{1,r-1}],cfg.tiempos(r-1).puntos,:),1)));

            [subj_vec_m(:,r)] = subj_vec_m(:,r)-baseline_val;
            for s = 1 : length(tiempo_m)
                subj_vec_mRT(s,r) = cfg.tiempos(r-1).tiempos(tiempo_m(s));
            end
            
        end
        
    elseif strcmp(flag, 'do')
        for r = 2:size(cfg.tiempos,2)+1
            baseline_val = squeeze(mean(mean(EEG.data([cfg.rois{1,r-1}],baseline_times.puntos,:),1)));
           
            [subj_vec_m(:,r), tiempo_m] = min(squeeze(mean(EEG.data([cfg.rois{1,r-1}],cfg.tiempos(r-1).puntos,:),1)));
            [subj_vec_m(:,r)] = subj_vec_m(:,r)-baseline_val;

            for s = 1 : length(tiempo_m)
                subj_vec_mRT(s,r) = cfg.tiempos(r-1).tiempos(tiempo_m(s));
            end
            
        end
        
    end
end
end


