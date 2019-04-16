function output = r2prime_chan(id) 
% T2 & T2* mapping
% @wf  - 2019032    - resume custom
% @wf  - 20181206   - customize for lncd/rhea from @chm code
%
%
%{
1. T2prep_gre_t2t2star sequence acquires mutli-echo (N_T2star) GRE data (for T2* mapping) 
per one spin-echo time, and repeated acquisition with different spin-echo time (N_T2) 
(for T2 mapping). So, the data consists in N_T2star*N_T2 files.

2. The mapping script uses NIfTI file format - Use "dcm2niix", Chris Rorden's dcm2niiX version 
v1.0.20170821 GCC5.4.0 (64-bit Linux)

3. Data foler consists of "StudyName(ex, 20190930)", and the subfolders of "Anylze", "DICOM", 
and "Processing". "Anylze" - nifti files; "Processing" - matablab program
and result files
%}

% Nifti library files are required to read and save
addpath(genpath('/opt/ni_tools/matlab_toolboxes/NIfTI/'));

% smoothed by 3x3x3
% N_T2star(5) files are for T2star mapping data, and N_T2(3) groups of
% T2 mapping files

%% create files
filelist = create_t2t2star_resamp(id);
% 12 files, 3 sets of 4
% first protocol is T2*
% first echo of each is T2

% go 3 parts above filename
% subjs/10644_20180216/R2prime/raw/3x3x3/blah.nii.gz
% subjs/10644_20180216/R2prime/chan_ver
basedir = fileparts(fileparts(fileparts(filelist{1})));
pfolder = fullfile(basedir,'chan_ver');
mkdir(pfolder)

output.t2map = fullfile(pfolder,'T2map.nii');
output.m0    = fullfile(pfolder,'M0T2map.nii');
output.t2smap= fullfile(pfolder,'T2Starmap.nii');
output.m0s   = fullfile(pfolder,'M0T2Starmap.nii');
output.r2prime=fullfile(pfolder,'r2prime.nii.gz');

%% do we already have everything?
files_exist = cellfun(@(x) exist(output.(x), 'file'),fieldnames(output));
if all(files_exist), return, end


%% Parameters
idxT2  = [1 5 9]; % First indices in filelist for T2
idxT2s = [1 2 3 4] + 0; % First indices in filelist for T2star

TET2  = [40 60 100]*1e-3; %Spin echo time i sec
TET2s = [2.5 5.0 7.5 10.0]*1e-3; %GRE echo time in sec

nT2  = length(idxT2);
nT2s = length(idxT2s);


%% Processing
%
T0 = clock;

fname = filelist{1};
image = load_untouch_nii(fname);
data = double(image.img);
[nx,ny,nz] = size(data);

T2data = zeros(nx,ny,nz,nT2);
T2sdata = zeros(nx,ny,nz,nT2s);

for i=1:nT2,
    fname = filelist{idxT2(i)};
    image = load_untouch_nii(fname);
    data = double(image.img);
    
    T2data(:,:,:,i) = data(:,:,:);
end
for i=1:nT2s,
    fname = filelist{idxT2s(i)};
    image = load_untouch_nii(fname);
    data = double(image.img);
    
    T2sdata(:,:,:,i) = data(:,:,:);
end

% Background threshold
threshT2  = 0.5*mean(T2data(:));
threshT2s = 0.5*mean(T2sdata(:));

% T2 mapping
[TT,AA] = t2fitLin(single(T2data),TET2',threshT2); 
%save('T2map.mat', 'TT', 'AA'); 
image.img = TT*1e+3; save_untouch_nii(image,output.t2map);
image.img = AA; save_untouch_nii(image,output.m0);

% T2star mapping
[TT,AA] = t2fitLin(single(T2sdata),TET2s',threshT2s); 
%save('T2smap.mat', 'TT', 'AA'); 
image.img = TT*1e+3; save_untouch_nii(image,output.t2smap);
image.img = AA; save_untouch_nii(image,output.m0s);


T1 = clock;
eT1T0 = etime(T1,T0);
%save eT1T0.mat eT1T0
disp(eT1T0);
%*notzero(a*b)
cmd=sprintf('3dcalc -a %s -b %s -expr "b - a" -prefix %s -overwrite', ...
            output.t2smap, output.t2map, output.r2prime);
if system(cmd) ~= 0, error('error running %s', cmd), end


end
