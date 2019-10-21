function [sym ,count ] = symbolic_transfer(signal,kernel, Fs, taus,data_sel,path,fileName)

cfg.kernel = kernel; %% kernel (cantidad de muestras que se utiliza para realizar la transformación) 
                    %%, para poner/cambiar el kernel == 4 hay que corregir PE_paralel!
cfg.chan_sel = 1:size(signal,1);  %% all channels
cfg.sf = Fs; %% sampling frequency
cfg.taus = taus; % Ver taus en do_MI_final.m // ultimos dos agregados por mi - Eze
cfg.data_sel = data_sel;

data = signal;

[sym ,count ] = s_transf(data,cfg);
dir_st = fullfile(path,'Results','ST');
if ~exist(dir_st,'dir')
    mkdir(dir_st);
end
save(fullfile(dir_st,[fileName,'_CSD.mat']),'sym','count');
