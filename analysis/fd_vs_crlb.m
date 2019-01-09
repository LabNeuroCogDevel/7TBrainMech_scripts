
%
% 
%



addpath('/Volumes/Zeus/DB_SQL') % get db_query.m
% SI1_to_nii for reading in sheet
addpath('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/Codes_yj/') 


allfd = dir('/Volumes/Hera/Projects/7TBrainMech/subjs/*/preproc/rest/motion_info/fd.txt');

%% luna ids
id = regexp([allfd.folder],'\d{5}_\d{8}','match')';

%% individual
fd_file = fullfile(allfd(1).folder, allfd(1).name);
fd = load(fd_file);
mean(fd)

%% for loop
n=length(allfd);
fd_means=zeros(n,1);
for i = 1:n
    fd_means(i) = mean(load(fullfile(allfd(i).folder,allfd(1).name)));
end

%% arrayfun
fd_means_2 = arrayfun( @(f) mean(load(fullfile(f.folder, f.name))), allfd)';

%% make table
fd_table = table(id, fd_means);


%% get age from database, join to fd_table
ages = unique(db_query([...
    'select concat(id, ''_'', to_char(vtimestamp, ''yyyymmdd'')) as id, age ' ...
    ' from visit natural join visit_study natural join enroll ' ...
    ' where etype like ''LunaID'' ' ...
    ' and study like ''%Brain%'' '...
    ' and vtype like ''%scan%''']));

fd_age = join(fd_table,ages);
writetable(fd_age,'fd_ages.csv');

%% read spreadsheet
allsheets = dir('/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/*/SI1/spreadsheet.csv');
sheets = table(...
         regexp([allsheets.folder],'\d{8}[^/]*','match')',...
         arrayfun(@(x) fullfile(x.folder,x.name), allsheets,'UniformOutput',0), ...
         'VariableNames',{'mrid','sheet'});
lunaid_7TID = unique(db_query([...
    'select '...
    ' luna.id as lunaid, '...
    ' mr.id as mrid, ' ...
    ' concat(luna.id, ''_'', substr(mr.id,1,8)) as id ' ...
    'from enroll as luna join enroll as mr on '...
    '  mr.etype=''7TMRID'' and luna.etype=''LunaID'' and '...
    '   mr.pid=luna.pid'...
    ]));
% fix 20180129 => 20180129Luna
sheets.mrid{strncmp('20180129',sheets.mrid,8)}='20180129Luna';
sheet_id_all = outerjoin(sheets, lunaid_7TID, 'Key','mrid','Type','Left');
% only matches
sheet_id = sheet_id_all(~arrayfun(@(x) isempty(x{1}), sheet_id_all.lunaid),{'lunaid','id','sheet'});
% missing 
regexp(...
    [sheet_id_all.sheet{arrayfun(@(x) isempty(x{1}), sheet_id_all.lunaid)}],...
    '\d{8}[^/]*','match')


% how to threshold inv crlb value
thres=@(x) (1 ./ x) < 20;

clear smry_metric
% smry_metric = struct(height(sheet_id))
for row=1:height(sheet_id)
    csi_csv=sheet_id.sheet{row};
    % read in spreadsheet into struct of matricies
    csivals = SI1_to_nii(csi_csv,[],[]);
    
    % csi rois
    csi_roi_dir = ...
        sprintf('/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/MRSI/2d_csi_ROI/',...
            sheet_id.id{row});
    try 
        tissue_file = strtrim(ls(fullfile(csi_roi_dir,'*_MaxTissueProb_FlipLR')));
        tissue=read_in_2d_csi_mat(tissue_file);
        gm=read_in_2d_csi_mat(strtrim(ls(fullfile(csi_roi_dir,'*_FractionGM_FlipLR'))));
    catch
        tissue=Inf(24,24);
        gm=Inf(24,24);
    end

    tissue_i = tissue>.6;
    smry_metric(row).inTissue_n = nnz(gm(tissue_i));
    smry_metric(row).gmRatInTissue_Mean = mean(gm(tissue_i));
    
    
    crlb_cre_thres  = thres(csivals.Cre_SD_inv);
    careabout = {'GABA','Glu'};
    
    % for each roi
    for roi=careabout
        
        % variables
        roi=roi{1};
        val = csivals.([roi '_Cre']);
        crlb = csivals.([roi '_SD_inv']);
        crlb_t  = thres(crlb);
        crlb_i = crlb_t & crlb_cre_thres;
        i = crlb_i & tissue_i;
        
        % find victor rois
         
        
        % summary calculations
        smry_metric(row).id = sheet_id.id(row);
        smry_metric(row).([roi '_GMratMean']) = mean(gm(i));
        smry_metric(row).([roi '_inGM_n']) = nnz(val(i & gm > .6) );
        smry_metric(row).([roi '_inGM_Mean']) = mean(val(i & gm > .6) );
        smry_metric(row).([roi '_crlb_n']) = nnz(crlb_i);
        smry_metric(row).([roi '_tissue_n']) = mean(val(i));
        smry_metric(row).([roi '_Mean']) = mean(val(i));
        smry_metric(row).([roi '_CRLB']) = mean( 1 ./ crlb(i));
        smry_metric(row).([roi '_std']) = std(val(i));

        smry_metric(row).([roi '_allCRLB']) = mean( 1 ./ crlb(crlb < 999 & crlb~=0));


    end
end

all_measures = outerjoin(...
               join(sheet_id,...
                    struct2table(smry_metric)),...
               fd_age,...
               'Type','Left');
writetable(all_measures,'all_measures_20190109.csv')