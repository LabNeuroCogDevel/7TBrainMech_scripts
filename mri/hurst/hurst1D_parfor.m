function H_all = hurst1D_parfor(roi_ts_1d, nroi)
% HURST1D_PARFOR - run hurst on all 1D files in dir() struct (.folder, .name)

   addpath(genpath('/opt/ni_tools/matlab_toolboxes/wmtsa/'))
   addpath(genpath('/opt/ni_tools/matlab_toolboxes/nonfractal/'))

   lb = [-0.5 0];
   ub = [1.5 10];
   % initialize and run in parallel
   H_all=zeros(length(roi_ts_1d), nroi);
   parfor di=1:length(roi_ts_1d)
      d = roi_ts_1d(di)
      % nvol x nroi (220x13)
      ts = load(fullfile(d.folder,d.name));
      [H, nfcor, fcor] = bfn_mfin_ml(ts, 'filter', 'Haar', 'lb', lb, 'ub', ub);
      % size(H) = 1x13 (nROI)
      % size(nfcor) == size(fcor) == nRoi x nROI == 13x13
      H_all(di,:) = H;
   end
end
