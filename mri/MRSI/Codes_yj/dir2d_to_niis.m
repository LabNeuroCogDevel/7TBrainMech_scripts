function dir2d_to_niis(dir_2d,dir_nii,tmpl_img)
% write as nifti if we have a csi_template image 
   if isa(tmpl_img,'char')
        tmpl_img = load_untouch_nii(tmpl_img);
   end
   if ~exist(dir_nii,'dir'), mkdir(dir_nii), end
   
   files=dir(dir_2d);
   for i=1:length(files)
       % skip nifti files
       if strncmp('.nii',files(i).name,4)
           fprintf('skip %s\n',files(i).name);
           continue
       end
       
       data = fullfile(files(i).folder,files(i).name);
       nii_out=fullfile(dir_nii,[files(i).name '.nii']);
       try
          csi2d_to_nii(data, nii_out, tmpl_img);
       catch e
           disp(e)
       end
   end
    
end