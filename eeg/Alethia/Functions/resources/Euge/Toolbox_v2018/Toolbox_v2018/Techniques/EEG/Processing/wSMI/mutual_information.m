function mutual_information(path,fileName,sym, taus)

direc = path;
dir_st = fullfile(direc,'Results','ST');
dir_smi = fullfile(direc,'Results','SMI');
if ~exist(dir_st,'dir')
    mkdir(dir_st);
end
if ~exist(dir_smi,'dir')
    mkdir(dir_smi);
end
file = fullfile(dir_st,[fileName,'_CSD.mat']);
fileout= fullfile(dir_smi,[fileName,'_CSD.mat']);
mutual_information_calculation(file,fileout,sym, taus);