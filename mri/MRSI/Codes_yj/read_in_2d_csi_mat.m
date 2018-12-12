function m = read_in_2d_csi_mat(f)
  % read_in_2d_cs_mat Read file written by csi_roi_label or parc_at_csi_*.m
  if ~exist(f,'file'); m=[]; return; end
  fid = fopen(f);
  m = fread(fid,'float');
  s = repmat(sqrt(numel(m)),1,2);
  m = reshape(m, s);
  fclose(fid);
end