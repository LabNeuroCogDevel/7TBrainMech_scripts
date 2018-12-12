% compare the final output before and after large code edits
% big change in 
%   17_ParcelCSIvoxel_FlipLR  -- roi ids changed
% 
% ddir='/Volumes/Hera/Projects/7TBrainMech/subjs/11686_20180917/slice_PFC/MRSI/Processed/'
% qc_m=@(n) compare_matout(fullfile(ddir,'mprage/',n),fullfile(ddir,n))
% qc_m('17_1_FlipLR.MPRAGE')
%
% qc_csi=@(n) compare_matout(fullfile(ddir,'parc_group/',n),fullfile(ddir,'parc_group_v4/',n))
% qc_csi('17_FractionGM_FlipLR')
% % see compare_changes() below

function [n_big_changes, max_change, rat_diff] = compare_matout(f1,f2)
  a = read_in_2d_csi_mat(f1);
  b = read_in_2d_csi_mat(f2);
  if(isempty(a) || isempty(b))
      n_big_changes=nan; max_change=nan; rat_diff=nan;
      return;
  end
 
  d=a-b;
  n_big_changes = nnz(abs(d) > 10^-3);
  rat_diff = n_big_changes/nnz(max(a,b)>10^-3);
  max_change = max(max(abs(d)));
  
  %return
  
  fprintf('nvox diff>thes / max(a,b)>thes: %.04f\n',rat_diff); 
  fprintf('max abs diff: %.04f in range %.02f-%.02f\n',...
      max_change, min(min(min(a,b))),max(max(max(a,b))));
  fprintf('diff > 10^-3: %d\n', n_big_changes);
  
  
  f=figure;
  [~,n] = fileparts(f1);
  title(n);
  subplot(2,2,1);
  imagesc(a);
  subplot(2,2,2);
  imagesc(b);
  subplot(2,2,3);
  imagesc(d);
  subplot(2,2,4);
  hist(reshape(d,[],1))
  
end

function m = read_in_2d_csi_mat(f)
  if ~exist(f,'file'); m=[]; return; end
  fid = fopen(f);
  m = fread(fid,'float');
  s = repmat(sqrt(numel(m)),1,2);
  m = reshape(m, s);
  fclose(fid);
end

function out = compare_changes()
 qc_csi = @(n) compare_matout(fullfile(ddir,'parc_group/',n),fullfile(ddir,'parc_group_v4/',n));
 fls=dir(fullfile(ddir,'parc_group'));
 names= {fls(~cellfun(@isempty,regexp({fls.name},'^(17_|[^0-9]).*FlipLR.*'))).name};
 t = table(names', 'VariableNames',{'n'});
 % run compare function for each output matrix, get nc mx and rt columns
 out = [t rowfun(@(n) qc_csi(n{1}),t, 'OutputVariableNames',{'nc','mx','rt'})];
 writetable(out,'changes_prob_output.txt')
 max(out.mx(out.mx<9),[],'omitna')
end
