%% editables
clear all
close all
clc

%% Path
addpath(genpath('Functions'));
Resultados_folder = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Results/ERPs');
datapath = hera('Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/PermutEpoch');
%% Parameters
% Dataset conditions
condition{1} = 'ITI';
condition{2} = 'Cue';
condition{3} = 'DotR_p3';
condition{4} = 'DotL_n3';
condition{5} = 'Delay';
condition{6} = 'MVSR_p5';
condition{7} = 'MVSL_n5';

% ventana = 'given'; % or 'SIGNI' if signi you need to stipulate the
% comparissons and run Permutame.m 

% Window for the extraction, goes to the output name
ventana = 'given'; % or 'SIGNI' to set the time for calculations. 
% late memory ERP / Blink?
% ven = [0.6 0.7];  cond = 'lmen_'; cfg.pretag = [condition{6},'_GAv'] ;

% % late visual ERP / Blink?
%  ven = [0.3 0.4]; cond = 'lVis_'; cfg.pretag = [condition{3},'_GAv'] ;

% % early visual ERP
ven = [0.1 0.2];cond = 'eVis_'; cfg.pretag = [condition{3},'_GAv'] ;

% grand average for each condition
cfg.orig_dir_uno=datapath;
cfg.orig_dir_dos=datapath;

%Rois Parietal (R y L), Frontal lateral (R y L), partially invented
cfg.rois{1}=[5 6 7]; %left-frontal
cfg.rois{2}=[40 39 38]; %fronto-central
cfg.rois{3}=[22 23 31]; %left-parietal
cfg.rois{4}=[31 59 58]; %right-parietal
cfg.rois{5}=[cfg.rois{1} cfg.rois{2} cfg.rois{3} cfg.rois{4}]; % All
cfg.rois{6} = [32 23 59 31 24 60 58];

%% Tiempos. Si son de la ventana significatica los saca del escript de permutaciones y si no los genera desde el EEG
cfg.base_time = 0.2;
cfg.baseline = [-.2,0];
tosbl = '_bl200ms';

% tosbl = strrep(strcat(num2str(cfg.baseline (1,1)),'_',num2str(cfg.baseline (1,2))),'.','_');

cfg.normaliza_datos = 666; % FLAG = 1 to normalize values to cfg.baseline
% Ventan significativa
if strcmp(ventana,'SIGNI')
    cfg.set_uno_filename=[condition{3},'_GAv.set']; cfg.set_name1=[condition{3},'_GAv'];
    cfg.set_dos_filename=[condition{7},'_GAv.set']; cfg.set_name2=[condition{7},'_GAv'];
    cfg.gruping = 'off';
    % nombre figuras
    cfg.name_fig=['ROI',cfg.set_name1, 'Vs' cfg.set_name2];
    cfg.outputpath = [Resultados_folder,'/',cfg.set_name1, 'Vs' cfg.set_name2, '/'];
    [times] = Permutame( cfg );
    close all
    
    c_times = struct('puntos',{},'tiempos',{}) ;
    
    for r = 1:length(times)
        c_times(r) = cleaned_times(times(r));
    end
    cfg.tiempos = c_times;
    
    filename_out = [cond,'win_signi',tosbl];
elseif strcmp(ventana,'given')
    tostr = strrep(strcat(num2str(ven(1,1)),'_',num2str(ven(1,2))),'.','_');

    cfg.ventana = [ven];
    filename_out = strcat(cond,'win_',tostr,tosbl);
    
    v_timesBase = puntos_times(cfg);
    v_times(1:5) = v_timesBase;
    cfg.tiempos = v_times;
end

[matriz] = extract_caracteristicas(cfg,filename_out);
