function [h,max_cond]=plot_std_met(mat,tiempo,color,lineastyle)
%Esta funcion nos permite graficar las metricas  con el valor medio del ERP 
%(ya sean trials o sujetos) y, ademas, le agrega una sombra como el desvio
%standar
%
%INPUTS:
%mat= es una matrix en dos dimensiones. La primer dimension tiene que ser el 
%los pasos en los que se hicieron las comparaciones (ya sea punto por punto para las
%permutaciones o por steps para los otros metodos)tiempo del erp. La tercera dimension puede ser
%"sujetos" o "trials" (esta tercera dimensions es la que se va a colpasar 
%para graficar la media del erp y su desvio).
%
%tiempo=variable que tiene la cantidad de steps o puntos que se estan
%comparando
%
%color=elegis el color en el cual se plotea el erp a partir de las opciones
%que da matlab de colores. Hay que ingresar la letra como una variable de
%texto
%
%linea=elegis el line style, si no se completa va linea solida
%
%ADVERTENCIA
%La variable tiempo y la primera dimension de la variable mat tienen que
%medir lo mismo, sino el script va a tirar error.

%% (1) Empiezo a laburar con la matriz erp
data=mat;
%data=squeeze(erp); % tiempo x trials
t=tiempo;
%define los colores que voy a utilizar para plotear
color_code{1}=color;
%defino si quiero linea punteada o linea solida o lo que garcha quiera

if nargin>3
    lineastyle
else
    lineastyle='-';
end

%% (2) Calcula el promedio y desvio standar de la señal
cond_avg=squeeze(nanmean(data,2));
cond_std=squeeze(nanstd(data,[],2));
max_cond=max(max(cond_avg) + (cond_std / sqrt(size(data,2))));
%calcula el error a partir del cual va a dibujar la sombra
mean_plus_error = cond_avg + (cond_std / sqrt(size(data,2))); % no of epochs
mean_min_error = cond_avg - (cond_std / sqrt(size(data,2)));


%% (3) Comenzamos a hacer el grafico
f_l=fill([t t(end:-1:1)],[mean_plus_error; mean_min_error(end:-1:1)],color_code{1},'EdgeColor',color_code{1}); %shaded error bar
hold on
h = plot(t,cond_avg, 'Color',color_code{1}, 'LineWidth', 2,'LineStyle',lineastyle);
set(f_l,'FaceAlpha',.3,'EdgeAlpha',.3)

%% (4) Creamos el cero vertical y el cero horizontal
horizontal(1:length(t))=0;
plot(t,horizontal,'Color',[0.600 0.600 0.600],'LineWidth',1,'LineStyle','--');
hold on

yL = get(gca,'YLim');
line([0 0],yL,'Color',[0.600 0.600 0.600],'LineWidth',1,'LineStyle','--');


end