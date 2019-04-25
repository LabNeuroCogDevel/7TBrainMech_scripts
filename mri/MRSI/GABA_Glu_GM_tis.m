%% GABA, Glu, GM, tissue

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
%% print to file
fid=fopen('GABA_Glu_GM_tis_20190418.txt','w');
fprintf(fid, 'LunaID DOB Sex Row Col Measure Crlb CSI ROI Amount FracTis FracGM\n')
for subj_i=1:nsubject
   try
        csi=readtable(s{subj_i}.csi);
        dob = s{subj_i}.dob;
        sex = s{subj_i}.sex;
        lunaid = s{subj_i}.subj_id;
        fractis = read_in_2d_csi_mat(s{subj_i}.fractis_file);
        fracgm = read_in_2d_csi_mat(s{subj_i}.fracgm_file);
        fracroi = load(s{subj_i}.fracroi);
        bestroi = nan(24,24);
        roiamount = nan(24,24);
        for i=1:24
            for j=1:24
                rois_at_vox = squeeze(fracroi.parc_comb_prob(i,j,:));
                [v,mi]=max(rois_at_vox);
                bestroi(i,j) = mi;
                roiamount(i,j) = v;
                
            end 
        end 
        for measure={'GABA_Cre', 'Glu_Cre'}
            measure=measure{1};
            crlb_name = regexprep(measure,'_Cre','_SD');
            m = csi.(measure); 
            crlb = csi.(crlb_name);
            for col_i = unique(csi.Col)'
                for row_i = unique(csi.Row)'
                    i = find(csi.Row==row_i & csi.Col==col_i);
                    if isempty(i), continue, end
                    val = m(i);
                    fprintf(fid,'%s %s %s %d %d %s %.3f %.3f %d %.3f %.3f %.3f\n', ...
                        lunaid, dob, sex,row_i, col_i, measure, crlb(i), val,...
                        bestroi(row_i, col_i), roiamount(row_i, col_i), fractis(row_i, col_i), fracgm(row_i, col_i));
                end
            end
          
        end
       
    catch e
       disp(e);
    end
end 
fclose(fid);
