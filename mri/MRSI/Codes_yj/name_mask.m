function [output_fname] = name_mask(name,matter)
%name_mask Name a mask given name and grey or white matter
%   e.g. "CAcing_gm.nii"
% thalamus, csf, brainstem, basal_ganglia are gm only
% their output names will not have _wm or _gm (e.g. basal_gangial.nii)
% USEAGE: add 'nii' column 
%    t = readtable(filename_table,'ReadVariableNames',1);
%    t = [t rowfun(@name_mask,t(:,{'name','matter'}),'OutputVariable','nii')];
%
  if isempty(name)
      output_fname = '';
      return
  end
  
  if isempty(matter) || strncmp(matter,'',1)
      output_fname=name;
  else
      output_fname=strcat(name, '_', matter);
  end
  output_fname = strcat(output_fname,'.nii');

end

