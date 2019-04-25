%% OVERVIEW  %%%%%%%
% 20190207 MP/WF 
% 1) look at all csi spreadsheet.csv files
% 2) get luna_date for each of those files
% 3) run csi_roi_vox

addpath('/Volumes/Zeus/DB_SQL');

%% find the subjects we have
% also remove duplicates and ones without files 
files= [ dir('/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/*L*/SI1/spreadsheet.csv')
         dir('/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/*/*L*/SI1/spreadsheet.csv')];
         
csi_visits_all = cellfun(@(x) basename(dirname(x)), {files.folder}, 'Un',0);
csi_visits = unique(csi_visits_all);
s = cellfun(@subject_files,csi_visits','Un',0);
%d = struct2table([s{:}]); % datatable not used, but might be useful

% warn about people we cannot find
missing_i = cellfun(@isempty,s);
unknown_csi = csi_visits(missing_i);
n_miss = nnz(missing_i);
if ~isempty(unknown_csi)
    warning('cannot find %d files: %s', n_miss, strjoin(unknown_csi));
    % remove missing
    s = s(~missing_i);
    csi_visits = csi_visits(~missing_i);
end
fprintf('found %d but only %d unique & %d missing\n', ...
    length(csi_visits_all), length(csi_visits), n_miss);


%% get rois for all
nroi=13; nsubject=length(s);
rois_max_row = nan(nroi, nsubject);
rois_max_col = nan(nroi, nsubject);

%% process csi
for i=1:nsubject
    try
        parc_comb = csi_vox_probcomb(s{i});
        %merging ROIs
        parc_comb(:,:,12)=parc_comb(:,:,1)+parc_comb(:,:,3);
        parc_comb(:,:,13)=parc_comb(:,:,2)+parc_comb(:,:,4);
       
        % we can try with greymatter
        fractis = read_in_2d_csi_mat(s{i}.fractis_file);
        fracgm = read_in_2d_csi_mat(s{i}.fracgm_file); % 24x24 matrix
        [rois_max_row(:,i), rois_max_col(:,i)] = gmmax_vox_tis(parc_comb, fracgm, fractis);
    catch e
        fprintf('error when running %s (bad scout resize? missing data? not in db?)\n', csi_visits{i})
        warning(e.message)
    end
end

%% print to file
fid=fopen('csi_roi_gmmax_tis_values_20190411.txt','w');
for subj_i=1:nsubject
   try
        csi=readtable(s{subj_i}.csi);
        dob = s{subj_i}.dob;
        sex = s{subj_i}.sex;
        lunaid = s{subj_i}.subj_id;
        for roi_j=1:nroi
            for measure={'GABA_Cre', 'GABA_SD', 'Glu_Cre', 'Glu_SD', 'Cre', 'Cre_SD', 'Gln_Cre', 'Gln_SD'}
                measure=measure{1}; %make it a string 
                max_roi_subj_col=rois_max_col(roi_j,subj_i);
                max_roi_subj_row=rois_max_row(roi_j,subj_i);
                    val=extract_csi_by_pos(csi, measure, max_roi_subj_row, max_roi_subj_col);
                    if isempty(val), val=0; end
                    fprintf(fid, '%s %s %s %d %s %.3f\n', lunaid, dob, sex, roi_j, measure, val);
            end
        end 
    end
end 
fclose(fid);
