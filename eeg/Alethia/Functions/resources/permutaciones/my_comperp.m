
%VERSION 1

modo=input('Ingreso manual de paramentros si/no:')
%poner si para manual y no para automatico
if strcmp(modo,'si')
%identificar el canal y el alpha de .05
    canales=input('Ingrese canales a plotear []: ')
    alpha=input('Ingrese valor de p: ')
    base_time=input('Ingrese tiempo de baseline: ')
%primero cargar los dataset que me interesan en el eeglab

    cond1_temp=input('Ingrese numero de dataset condicion 1: ')
    cond2_temp=input('Ingrese numero de dataset condicion 2: ')
%etiquetar las condiciones que se cargaron
    cond_temp(1).name=input('Ingrese nombre de la condición 1: ')
    cond_temp(2).name=input('Ingrese nombre de la condición 2: ')

else

    canales=[87 86 85 84 83 82 88 89 90 91 92 99 100 96 95 101 102 103 104 105 106 107 108 109 98 75 76 77 75 79 74 73 67 68 69 70 66 64 63 62 61 60];
    alpha=-0.05
    base_time=0.2

    cond1=1
    cond2=2
    cond(1).name='cont_mot'
    cond(2).name='cont_int'
end

salvar=0
newsr=EEG.srate
erp=['ERP'];

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve',cond1_temp,'study',0);
eeglab redraw
cond_temp(1).data=EEG.data;
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve',cond2_temp,'study',0);
eeglab redraw
cond_temp(2).data=EEG.data;



disp('Condition loaded')


%% 

askroi=input('Desea armar ROIs si/no:');

if strcmp(askroi,'si')
  
    i=1;
    ingreso_otro=1;
    
    while ingreso_otro==1
        
        roi(i).chans=input(['Ingrese ROI ' num2str(i) ' [] :'])
       
        if  isempty(roi(i).chans)
            ingreso_otro=0;
        end
         i=i+1;
    end
   
 
    
    for k=1:size(roi,2)-1
    
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
    
else
    cond1=cond1_temp;
    cond2=cond2_temp;
end

cond(1).name=cond_temp(1).name;
cond(2).name=cond_temp(2).name;
%%

for j=1:size(cond(1).epochs,1)

    cond(1).mean(j,:,:)=squeeze(mean(cond(1).epochs(j,:,:,:),2));
    cond(2).mean(j,:,:)=squeeze(mean(cond(2).epochs(j,:,:,:),2));

end
%canales=input('Ingrese canales a plotear entre [] : ')
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
 
        if salvar==1
 
            saveas(gcf,[out_path paciente '_Cond_' cond(i).name '_electrodo_' num2str(EEG.chanlocs(canal).labels) '_' band ],'fig')
        
        end
    end

    %%


   statistics
   plot_with_sem
    
    
    if salvar==1
 
    saveas(gcf,[out_path paciente '_' erp '_' tipo '_electrodo_' num2str(EEG.chanlocs(canal).labels) ],'fig')
    end
    
end 

disp('Terminado')

clear all
eeglab