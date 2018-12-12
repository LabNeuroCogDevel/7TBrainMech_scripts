function created_niis = grouping_masks(filename_table,dir_MPRAGE)
  % GROUPING_MASKS create roi masks from groups of freesurfer parcalations
  %   expects dir_MPRAGE to contain 
  %    1) aparc+aseg.nii and 
  %    2) wmparc.nii
  %   will dump out a nii file for each roi specified in filename_table
  %   tab separated table like:
  %      name     matter label  aparc_vals    wmpar_vals      
  %      abnormal gm     AGM    25 57 81 ...
  %      CAcing   wm     CACWM                3002 4002
  %rewritten parc_grouping_ft_plusExtras(ROI_dir) to take tsv table input


  %% load in white and grey matter
  % reuse img_nii to save out masks
  img_nii = load_untouch_nii(fullfile(dir_MPRAGE,'aparc+aseg.nii'));
  parc.gm = img_nii.img;
  img_nii = load_untouch_nii(fullfile(dir_MPRAGE,'wmparc.nii'));
  parc.wm = img_nii.img;
  

  %% load in roi specification
  t = readtable(filename_table,'ReadVariableNames',1);
  t = [t rowfun(@name_mask,t(:,{'name','matter'}),'OutputVariable','nii')];
  
  %% track the files we will create
  created_niis = cell(height(t),2);
  
  %% for each row, create a new nifti image using the freesurfer values
  % provided
  for i=1:height(t)
      % skip unnamed rows (THAwm and BGAwm)
      if isempty(t.name(i)), continue, end
      
      % what file are we making
      disp(t.nii{i});

      
      %% table row: freesurfer roi values and grey and/or white matter
      % most regions pull from only one gm or wm
      % frontal and parietal pull from both segmentations
      % abnormal_wm pulls from apac instead of wmparc
      % vals stores which fressurfer rois we want from aparc and wmpar
      vals.gm = str2double(strsplit(t.aparc_vals{i}));
      vals.wm = str2double(strsplit(t.wmpar_vals{i}));
            
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
      save_untouch_nii(img_nii, fullfile(dir_MPRAGE, t.nii{i}));
      
      %% track what we created
      created_niis(i,:) = {t.nii{i}, nnz(img_nii.img)};
  end

  % make a table of filename and count
  created_niis = cell2table(created_niis,'VariableNames',{'file','nnz'});

end