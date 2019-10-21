%% PERMUTACIONES VERSION 5. Pauli
% Este script hace permutaciones entre dos condiciones (ej. motor vs intero pre)
% y hace la estadistica para 4 Rois. SOLO MODIFICAR la parte de Configuracion
% te guarda los graficos.

%% 0. Configuracion: solo modificar esta parte del script !!!
clear all, close all, clc,
%DATASET UNO
cfg.orig_dir_uno='G:\PROTOCOLO_TRASPLANTADOS\Bloques\Tx_condiciones\Ev3\DIF_v1';
cfg.set_uno_filename='GranA_Ev3_mot_OyC.set';
cfg.set_name1='Ev3_mot_oyc';
%DATA SET DOS
cfg.orig_dir_dos='G:\PROTOCOLO_TRASPLANTADOS\Bloques\Tx_condiciones\Ev3\DIF_v1';
cfg.set_dos_filename='GranA_Ev3_pre_OyC.set';
cfg.set_name2='Ev3_pre_oyc';
%nombre figuras
name_fig='Ev3_pre_vs_mot_oyc'


%Roi1 EM !!! SOL
cfg.rois{1}=[92 91 95 96 83 84 85 86 79 78 73 74];
cfg.rois{2}=[92 91 95 96]; %Roi2 izq
cfg.rois{3}=[83 84 85 86]; %Roi3 centro
cfg.rois{4}=[79 78 73 74]; %Roi4 der

%rois ORIGINALES DE ADRI
% %Roi1
% cfg.rois{1}=[87 86 85 84 83 82 88 89 90 91 92 99 100 96 95 101 102 103 104 105 106 107 108 109 98 75 76 77 75 79 74 73 67 68 69 70 66 64 63 62 61 60];
% 
% cfg.rois{2}=[88 89 90 91 92 95 96 99 100]; %Roi2 izq
% cfg.rois{3}=[82 83 84 85 86 87 88 89 75 76]; %Roi3 centro
% cfg.rois{4}=[67 68 73 74 75 76 77 78 79]; %Roi4 der

%% De acá en mas no tocar nada mas que algun path!!!
%1. Levantar el dataset 1

addpath(genpath('D:\PAULI\Toolbox\eeglab14_1_1b'));
addpath('G:\Toolbox_Pauli\scripts\script permutaciones');
eeglab

EEG = pop_loadset('filename',cfg.set_uno_filename,'filepath',cfg.orig_dir_uno);
EEG = eeg_checkset( EEG );

eeglab redraw
cond1_temp= 1
cond_temp(1).name= cfg.set_name1
cond_temp(1).data=EEG.data;

%% 2. Levantar el dataset 2
 
EEG = pop_loadset('filename',cfg.set_dos_filename,'filepath',cfg.orig_dir_dos);
EEG = eeg_checkset( EEG );

eeglab redraw;

cond2_temp= 2
cond_temp(2).name= cfg.set_name2
cond_temp(2).data=EEG.data;


%% 3. ERPs
salvar=0
newsr=EEG.srate
erp=['ERP'];

%% 4. Definir Canales, Alpha y Baseline

%canales=input('Ingrese canales a plotear []: ')
canales = 1
%alpha=input('Ingrese valor de p: ')
alpha = 0.05
%base_time=input('Ingrese tiempo de baseline: ')
base_time = 0.3


%% 5. ROIs
    for p=1:size(cfg.rois,2) %Aca esta tomando de la estructura cfg.rois un stream para el numero de columna que es p
        roi(1).chans=cfg.rois{1,p}; % p es columna
            for k=1:size(roi,2)
                    temp=[];
                    temp2=[];
                    
                for j=1:size(roi(k).chans,2)
                    temp=cat(2,temp,squeeze(cond_temp(1).data(roi(k).chans(j),:,:)));
                    temp_epoch(j,:,:)=squeeze(cond_temp(1).data(roi(k).chans(j),:,:));
                    temp2=cat(2,temp2,squeeze(cond_temp(2).data(roi(k).chans(j),:,:)));
                    temp2_epoch(j,:,:)=squeeze(cond_temp(2).data(roi(k).chans(j),:,:)); 
                end
        
            cond(1).data(k,:,:)=temp;
            cond(1).epochs(k,:,:,:)=temp_epoch;
            cond(2).data(k,:,:)=temp2;
            cond(2).epochs(k,:,:,:)=temp2_epoch;
            end

cond(1).name=cond_temp(1).name;
cond(2).name=cond_temp(2).name;
%%

    for j=1:size(cond(1).epochs,1)
    cond(1).mean(j,:,:)=squeeze(mean(cond(1).epochs(j,:,:,:),2));
    cond(2).mean(j,:,:)=squeeze(mean(cond(2).epochs(j,:,:,:),2));
    end
%%
    for k=1:size(canales,2)
        figure
        canal=canales(k);

            for i=1:size(cond,2)

                subplot(2,2,i)
                imagesc((1:1:size(cond(i).mean,2))/newsr-base_time,1:1:size(cond(i).mean,3),squeeze(cond(i).data(canal,:,:))')
                title(['Cond: ' cond(i).name ' - electrodo: ' num2str(EEG.chanlocs(canal).labels) ])
                caxis([-2 2])

                line([0 0],ylim,'Color','k')
                set(gca,'XTick',(-0.5:0.1:1.5))
 
            if  salvar==1
                saveas(gcf,[fig1],'fig')
        
            end
    end
%% 6. Estadistica y figuras a guardar
   statistics
   plot_with_sem
   
% Guardar Fig: nombre ej. Roi1_cond1_cond2  

   saveas(gcf,['Roi',num2str(p),'_',name_fig],'fig')
  
    end 

disp('Terminado')

%borro variables que se reutilizan en el For
clear roi(1).chans k temp temp2 temp_epoch temp2_epoch cond j 

end

% clear all, close all, clc
% eeglab