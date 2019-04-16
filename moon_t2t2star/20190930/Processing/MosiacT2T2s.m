%
% T2 & T2* mapping
%
% @chm - 04/10/2018
%


%% Tools
addpath(genpath('/usr/local/matlabtools/NIfTI'));
addpath(genpath('/usr/local/matlabtools/utils'));


%% Path & files
pfodler = '/home/moonc/OngoingResearch/7T/Data/T2T2STAR/20190930/Analyze/';


% resoluton 2.29x2.29x3.0
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

%{
% smoothed by 3x3x3
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
%}

%% Parameters
idxT2  = [1 5 9];
idxT2s = [1 2 3 4] + 0;

TET2  = [40 60 100]*1e-3; %sec
TET2s = [2.5 5.0 7.5 10.0]*1e-3; %sec

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

MosaicImage1 = [];
for j=1:nT2,
    MosaicImage2 = [];
    for i=1:nT2s,
        fname = [pfodler filelist{1,idxT2s(i)+idxT2(j)-1}];
        image = load_untouch_nii(fname);
        data = double(image.img);

        T2sdata(:,:,:,i) = data(:,:,:);

        MosaicImage2 = [MosaicImage2 rot90(data(:,:,8),1)];

    end
    MosaicImage1 = [MosaicImage1; MosaicImage2];
end

figure(1); subplot(1,1,1); imagesc(MosaicImage1,[0 130]); axis image; colormap(gray); axis off;

%{
threshT2  = 0.5*mean(T2data(:));
threshT2s = 0.5*mean(T2sdata(:));

% T2
[TT,AA] = t2fitLin(single(T2data),TET2',threshT2); 
%save('T2map.mat', 'TT', 'AA'); 
image.img = TT*1e+3; save_untouch_nii(image,[pfodler 'T2map.nii']);
image.img = AA; save_untouch_nii(image,[pfodler 'M0T2map.nii']);

% T2*
[TT,AA] = t2fitLin(single(T2sdata),TET2s',threshT2s); 
%save('T2smap.mat', 'TT', 'AA'); 
image.img = TT*1e+3; save_untouch_nii(image,[pfodler 'T2Starmap.nii']);
image.img = AA; save_untouch_nii(image,[pfodler 'M0T2Starmap.nii']);
%}


T1 = clock;
eT1T0 = etime(T1,T0);
%save eT1T0.mat eT1T0
disp(eT1T0);