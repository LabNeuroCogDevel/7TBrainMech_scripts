function created4ds = grouping4d(table_fname,dir_MPRAGE)

  % load in white and grey matter
  % reuse img_nii to save out masks
  img_nii = load_untouch_nii(fullfile(dir_MPRAGE,'aparc+aseg.nii'));
  parc.gm = img_nii.img;
  img_nii = load_untouch_nii(fullfile(dir_MPRAGE,'wmparc.nii'));
  parc.wm = img_nii.img;
  

  % load in tab separated table like:
  %  name  matter   label fs_vals                                                                                                                                                                   
  %  abnormal gm AGM   25 57 81 82 101 102 103 104 105 106 107 110 111 112 113 114 115 116
  t = readtable(table_fname,'ReadVariableNames',1);
  
  % track the files we created
  created4ds = cell(height(t),2);
  
  % for each row, create a new nifti image using the freesurfer values
  % provided
  for i=1:height(t)
      % skip unnamed rows (THAwm and BGAwm)
      if isempty(t.name(i)), continue, end
      
      %% table row: freesurfer roi values and grey and/or white matter
      % most regions pull from only one gm or wm
      % frontal and parietal pull from both segmentations
      % abnormal_wm pulls from apac instead of wmparc
      % vals stores which fressurfer rois we want from aparc and wmpar
      vals.gm = str2double(strsplit(t.aparc_vals{i}));
      vals.wm = str2double(strsplit(t.wmpar_vals{i}));
      
      %% output name
      % thalamus, csf, brainstem, basal_ganglia are gm only
      % their output names will not have _wm or _gm (e.g. basal_gangial.nii)
      % others are like "CAcing_gm.nii"
      if isempty(t.matter{i})
          output_fname=t.name{i};
      else
          output_fname=strcat(t.name{i},'_',t.matter{i});
      end
      output_fname = strcat(output_fname,'.nii');
      disp(output_fname);
      
      %% find the values in the parcel for both gm and wm
      % most regions will have one of 
      % roi_mask.gm or roi_mask.wm as all zeros
      for m={'gm','wm'}
          m=m{1};
          if isempty(vals.(m))
              roi_mask.(m) = zeros(size(img_nii.img));
          else
              [roi_mask.(m), ~] = ROI_from_Parcel(parc.(m), vals.(m));
          end
      end
      img_nii.img = double(or(roi_mask.gm,roi_mask.wm));
      
      %% write nifti
      save_untouch_nii(img_nii, fullfile(dir_MPRAGE, output_fname));
      
      %% track what we created
      created4ds(i,:) = {output_fname, nnz(img_nii.img)};
  end

  % make a table of filename and count
  created4ds = cell2table(created4ds,'VariableNames',{'file','nnz'});

end