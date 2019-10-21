% clear Res_Prom configuracion_usada sujetos_uno sujetos_dos  
sm=3;


% ->>PS: ALGO DE ESTO NO DEBERIA ESTAR TMB ABAJO??????

%%
%PAULA: ESTA ADAPTACION QUE TE HAGO ES SOLO PARA CARGAR LAS DIFERENCIAS de
%los contoles x ejemplo (para hacer los pacientes tenès que cambiar la
%carpeta). si querès volver a hacer los otros datos comentà estas lìneas y descomenta las de arriba. 
cd ('C:\Users\Ineco\Desktop\Para Paula\Diferencias\Pacientes')
load ('dif_front.mat')
data=squeeze(dif_front);

% PS: esto lo agregue yo
load ('times.mat')
time=times(1,1:end)';
%%


aux=mean(data,2);
linea_solida=smooth(aux,sm);



cond_avg=squeeze(nanmean(data,2));
cond_std=squeeze(nanstd(data,[],2));
%calcula el error a partir del cual va a dibujar la sombra
mean_plus_error = cond_avg + (cond_std / sqrt(size(data,2))); % no of epochs
%mean_min_error = cond_avg - (cond_std / sqrt(size(data,2)));

arriba=smooth(mean_plus_error,sm);
%abajo=smooth(mean_min_error,sm);
open linea_solida
open arriba
open time

