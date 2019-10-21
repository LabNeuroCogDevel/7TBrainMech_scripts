function [ times,data_guardar ] = Permutame( cfg )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
% where to find eeglab stuff
addpath(hera('\Projects\7TBrainMech\scripts\eeg\Alethia\Functions\resources\permutaciones'))

eeglabpath = fileparts(which('eeglab'));
addpath(eeglabpath)
eeglab
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;


EEG = pop_loadset('filename',cfg.set_uno_filename,'filepath',cfg.orig_dir_uno);
EEG = eeg_checkset( EEG );

eeglab redraw
cond1_temp= 1;
cond_temp(1).name= cfg.set_name1;
cond_temp(1).data=EEG.data;

%% 2. Levantar el dataset 2

EEG = pop_loadset('filename',cfg.set_dos_filename,'filepath',cfg.orig_dir_dos);
EEG = eeg_checkset( EEG );

eeglab redraw;

cond2_temp= 2;
cond_temp(2).name= cfg.set_name2;
cond_temp(2).data=EEG.data;


%% 3. ERPs
salvar=0;
newsr=EEG.srate;
erp=['ERP'];

%% 4. Definir Canales, Alpha y Baseline

%canales=input('Ingrese canales a plotear []: ')
canales = 1;
%alpha=input('Ingrese valor de p: ')
alpha = 0.05;
%base_time=input('Ingrese tiempo de baseline: ')
base_time = 0.2;


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
            title(['Cond: ' cond(i).name ' - channels: ' num2str(roi.chans) ])
            caxis([-2 2])
            
            line([0 0],ylim,'Color','k')
            set(gca,'XTick',(-0.5:0.1:1.5))
            
            if  salvar==1
                saveas(gcf,[fig1],'fig')
                
            end
        end
        %% 6. Estadistica y figuras a guardar
        [tt df pvals] = statistics(cond,cfg.gruping);
        plot_with_sem
        
        
        [times(p).puntos]=find(pvals<alpha);
        
        epochsize=size(cond(i).data,2);
        srate_newepoch=EEG.srate;
        tepoch=[1:epochsize]/srate_newepoch-base_time;
        [times(p).tiempos]=tepoch(times(p).puntos);

        % Guardar Fig: nombre ej. Roi1_cond1_cond2
        
        saveas(gcf,[cfg.outputpath,'Roi',num2str(p),'_',cfg.name_fig],'fig')
        saveas(gcf,[cfg.outputpath,'Roi',num2str(p),'_',cfg.name_fig],'png')
        
    end
    
    disp('Terminado')
    
    %borro variables que se reutilizan en el For
    clear roi(1).chans k temp temp2 temp_epoch temp2_epoch cond j
    
end

% clear all, close all, clc
% eeglab

end

