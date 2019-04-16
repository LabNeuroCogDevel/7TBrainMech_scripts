%%
% T2 & T2* mapping
%
% @chm - 04/10/2018
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



%% Tools
% Nifti library files are required to read and save
addpath(genpath('/usr/local/matlabtools/NIfTI'));
%addpath(genpath('/usr/local/matlabtools/utils'));


%% Path & files
% Main folder for data and processing
pfodler = '/home/moonc/OngoingResearch/7T/Data/T2T2STAR/20190930/Analyze/';

%{
% resoluton 2.29x2.29x3.0 - raw data
filelist = {...
    's170808154908DST131221107523418914-0020-00001-000001-01.nii'...
    's170808154908DST131221107523418914-0020-00001-000033-02.nii'...
    's170808154908DST131221107523418914-0020-00001-000065-03.nii'...
    's170808154908DST131221107523418914-0020-00001-000097-04.nii'...
    's170808154908DST131221107523418914-0021-00002-000001-01.nii'...
    's170808154908DST131221107523418914-0021-00002-000033-02.nii'...
    's170808154908DST131221107523418914-0021-00002-000065-03.nii'...
    's170808154908DST131221107523418914-0021-00002-000097-04.nii'...
    's170808154908DST131221107523418914-0022-00003-000001-01.nii'...
    's170808154908DST131221107523418914-0022-00003-000033-02.nii'...
    's170808154908DST131221107523418914-0022-00003-000065-03.nii'...
    's170808154908DST131221107523418914-0022-00003-000097-04.nii'...
};
%}

% smoothed by 3x3x3
% N_T2star(5) files are for T2star mapping data, and N_T2(3) groups of
% T2 mapping files
filelist = {...
    'ss170808154908DST131221107523418914-0020-00001-000001-01.nii'...
    'ss170808154908DST131221107523418914-0020-00001-000033-02.nii'...
    'ss170808154908DST131221107523418914-0020-00001-000065-03.nii'...
    'ss170808154908DST131221107523418914-0020-00001-000097-04.nii'...
    'ss170808154908DST131221107523418914-0021-00002-000001-01.nii'...
    'ss170808154908DST131221107523418914-0021-00002-000033-02.nii'...
    'ss170808154908DST131221107523418914-0021-00002-000065-03.nii'...
    'ss170808154908DST131221107523418914-0021-00002-000097-04.nii'...
    'ss170808154908DST131221107523418914-0022-00003-000001-01.nii'...
    'ss170808154908DST131221107523418914-0022-00003-000033-02.nii'...
    'ss170808154908DST131221107523418914-0022-00003-000065-03.nii'...
    'ss170808154908DST131221107523418914-0022-00003-000097-04.nii'...
};


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

fname = [pfodler filelist{1,1}];
image = load_untouch_nii(fname);
data = double(image.img);
[nx,ny,nz] = size(data);

T2data = zeros(nx,ny,nz,nT2);
T2sdata = zeros(nx,ny,nz,nT2s);

for i=1:nT2,
    fname = [pfodler filelist{1,idxT2(i)}];
    image = load_untouch_nii(fname);
    data = double(image.img);
    
    T2data(:,:,:,i) = data(:,:,:);
end
for i=1:nT2s,
    fname = [pfodler filelist{1,idxT2s(i)}];
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
image.img = TT*1e+3; save_untouch_nii(image,[pfodler 'T2map.nii']);
image.img = AA; save_untouch_nii(image,[pfodler 'M0T2map.nii']);

% T2star mapping
[TT,AA] = t2fitLin(single(T2sdata),TET2s',threshT2s); 
%save('T2smap.mat', 'TT', 'AA'); 
image.img = TT*1e+3; save_untouch_nii(image,[pfodler 'T2Starmap.nii']);
image.img = AA; save_untouch_nii(image,[pfodler 'M0T2Starmap.nii']);


T1 = clock;
eT1T0 = etime(T1,T0);
%save eT1T0.mat eT1T0
disp(eT1T0);
