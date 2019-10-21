function [ v_times] = puntos_times(cfg)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
eeglab

EEG = pop_loadset('filename',[cfg.pretag '.set'],'filepath',cfg.orig_dir_uno);
EEG = eeg_checkset( EEG );

eeglab redraw

ini = abs(EEG.times - (cfg.ventana(1)*1000));
inic_point = find(ini == min(ini));

fin = abs(EEG.times - (cfg.ventana(2)*1000));
final_point = find(fin == min(fin));


v_times.tiempos=EEG.times([inic_point:final_point]);
v_times.puntos = [inic_point:final_point];

end

