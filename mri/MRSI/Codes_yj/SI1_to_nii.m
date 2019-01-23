function measures  = SI1_to_nii(csi_csv,tmpl_nii,outdir)
% SI1_TO_NII Create nii images from spreadsheet
%   if tmpl_nii and outdir are null, only return values read from sheet
%% inputs

% read in spreadsheet -- first 2 columns assumed to be 'Row' and 'Col'
csivals = readtable(csi_csv);


% template nifti file to dump data into
if ~isempty(tmpl_nii)
    tmpl = load_untouch_nii(tmpl_nii);
    n = size(tmpl.img);
else
    n= [24, 24];
end

% convert row, column to single index
i = sub2ind(n, csivals.Row, csivals.Col);

%% for each measure in the csv file
% extract matrix, add to nifti, save
if ~isempty(outdir) && ~exist(outdir,'dir'), mkdir(outdir), end
measures = struct();
for measure = csivals.Properties.VariableNames(3:end)
  name = measure{1};
  %disp(measure{1})
  m = zeros(n);
  m(i) = csivals.(measure{1});
  
  % invert SD for afni thresholding
  % 999 is total junk => now .0010
  % 20 is meaningful threshold: greather than .05 is good
  % 3 is great: .33
  if regexp(name,'SD$')
      m(i) = 1 ./ m(i);
      name = [ name '_inv' ];
  end
  
  if ~isempty(outdir)
     csi2d_to_nii(m, fullfile(outdir, [name '.nii']), tmpl);
  end
  
  % keep around to check col row
  measures.(name) = m;
end

% check
% measures.NAA(20,19) == csivals.NAA( csivals.Row == 20 & csivals.Col==19)
end