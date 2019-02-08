%% OVERVIEW  %%%%%%%
% 20190207 MP/WF 
% 1) look at all csi spreadsheet.csv files
% 2) get luna_date for each of those files
% 3) run csi_roi_vox

%% get all lunaid/7TMRID pairs -- to make a luna_scandate 
addpath('/Volumes/Zeus/DB_SQL');
query = [...
'    with ' ...
' st as (select * from enroll where etype like ''7TMRID''),'...
' l  as  (select * from enroll where etype like ''LunaID'')'...
'select'...
' concat(l.id, ''_'', substr(st.id,0,9)) as ld8, '...
' st.id as stid,'...
' dob, '...
' sex '...
' from st join l'...
' on st.pid = l.pid '...
'join person p on p.pid = st.pid'];

%% fetch data
d=db_query(query);

%% find the subjects we have
files=dir('/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/*/SI1/spreadsheet.csv');
csi_visits = cellfun(@(x) basename(dirname(x)), {files.folder}, 'Un',0);
have_idx = ismember(d.stid, csi_visits);
d_have_csi = d(have_idx,:);

%% get rois for all
nroi=11; nsubject=height(d_have_csi);
rois_max_row = nan(nroi, nsubject);
rois_max_col = nan(nroi, nsubject);

% todo 
for i=1:nsubject
    try
        [rois_max_row(:,i), rois_max_col(:,i) ] = csi_roi_vox(d_have_csi.ld8{i});
    catch
        fprintf('missing for subject %s\n',d_have_csi.ld8{i})
    end
end

% todo
% call function that will extract csi from max roi

fid=fopen('csi_roi_max_values.txt','w');
for subj_i=1:nsubject
    csi_csv=sprintf('/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/%s/SI1/spreadsheet.csv',d_have_csi.stid{subj_i});
    csi=readtable(csi_csv);
    for roi_j=1:nroi
        for measure={'GABA_Cre', 'GABA_SD', 'Glu_Cre', 'Glu_SD', 'Cre', 'Cre_SD'}
            measure=measure{1}; %make it a string 
            max_roi_subj_col=rois_max_col(roi_j,subj_i);
            max_roi_subj_row=rois_max_row(roi_j,subj_i);
            lunaid= d_have_csi.ld8{subj_i};
            val=extract_csi_by_pos(csi, measure, max_roi_subj_row, max_roi_subj_col);
            if isempty(val), val=0; end
            fprintf(fid, '%s %d %s %.3f\n', lunaid, roi_j, measure, val);
        end 
    end
end 
fclose(fid)