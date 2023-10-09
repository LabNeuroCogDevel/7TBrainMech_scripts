% read in roi time series (nvol x nroi) per subject (see mkTS_roi.bash)
% generate per visit Hurst Exponent (EI balance proxy measure)
% https://github.com/elifesciences-publications/ei_hurst/blob/master/code/C_1a_parcEst.m
% 20230508WF - init


addpath(genpath('/opt/ni_tools/matlab_toolboxes/wmtsa/'))
addpath(genpath('/opt/ni_tools/matlab_toolboxes/nonfractal/'))


%Non-fractal-master/m/bfn_mfin_ml.m args
% copied from ei_hurst elife paper
lb = [-0.5 0];
ub = [1.5 10];
rest_niis = dir('/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_ica/1*_2*/brnaswdkm_func_4.nii.gz')';
gm_mask_fname = '/opt/ni_tools/standard/mni_icbm152_nlin_asym_09c/mni_icbm152_gm_tal_nlin_asym_09c_2mm.nii';
mask_info = niftiinfo(gm_mask_fname);
gm_mask = niftiread(gm_mask_fname) > .2;
maski = find(gm_mask);

ld8s = regexprep({rest_niis.folder}, '.*/','');

% %% confirm matrix reshaping is okay
% addpath('/opt/ni_tools/matlab_toolboxes/imtool3D_td')
% eg=niftiread(fullfile(rest_niis(1).folder,rest_niis(1).name));
% x = reshape(eg, [prod(size(gm_mask)),220]);
% tmp = gm_mask; tmp(maski) = x(maski,1)
% imtool3D(tmp)

% initialize and run in parallel
n_visits = length(rest_niis)
H_all=zeros([size(gm_mask) n_visits]);
nvox = prod(size(gm_mask));
for di=1:n_visits
   outname=fullfile('hurst_nii/', [ ld8s{di} '/matlab_H.nii.gz'])
   if exist(outname,'file')
      tmp = niftiread(outname);
      H_all(:,:,:, di) = tmp;
      continue
   end

   d = rest_niis(di)
   %input should be: nvol x nvox (220x1082035)
   ts = niftiread(fullfile(d.folder, d.name));
   nvol = size(ts,4);
   ts = reshape(ts, [nvox, nvol])'; % 220x1082035
   ts = double(ts(:, maski));       % 220x174371 % 227531 in mni mask
   m = mean(ts);
   keepi = find(m);
   ts = ts(:,keepi); % 220 x 147695

   nvox_mask = size(ts,2);
   H=zeros([nvox_mask 1]);
   time, tic,
   parfor voxi=1:nvox_mask
      %  H, nfcor, fcor
      [H(voxi), ~, ~] = bfn_mfin_ml(ts(:,voxi),...
                        'filter', 'Haar', 'lb', lb, 'ub', ub);
   end
   tmp = zeros(size(gm_mask));
   tmp(maski(keepi)) = H;
   time, tic,
   %mask_info.Filename = outname;
   %mask_info.Desciption = ld8s{di};

   %NB. writen as .nii.nii instead of .nii.gz !?
   niftiwrite(tmp,outname); %,mask_info)

   % imtool3D(tmp)
   H_all(:,:,:, di) = tmp;
end

% save as a big nifti
niftiwrite(H_all,'husrt_nii_all.nii.gz');
