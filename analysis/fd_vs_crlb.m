
%
% read csi valus/rois to generage MRSI summary stats for subjects
% also attach rest motioin (FD) and age


%% functions stored elsewhere
addpath('/Volumes/Zeus/DB_SQL') % get db_query.m
% SI1_to_nii for reading in sheet
addpath('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/Codes_yj/') 

%% FD motion 
% from rest preprocessing
allfd = dir('/Volumes/Hera/Projects/7TBrainMech/subjs/*/preproc/rest/motion_info/fd.txt');

% lunaid_date from fd file names
id = regexp([allfd.folder],'\d{5}_\d{8}','match')';

%% example parsing/combining fd
% examples of how to read in fd data. only need one of the later 2
%%% 0. individual -- how to put together and read one file
fd_file = fullfile(allfd(1).folder, allfd(1).name);
fd = load(fd_file);
mean(fd)

%%% 1. for loop -- read in all data with a loop
n=length(allfd);
fd_means=zeros(n,1);
for i = 1:n
    fd_means(i) = mean(load(fullfile(allfd(i).folder,allfd(1).name)));
end

%%% 2. arrayfun -- same thing with less ceremony
fd_means_2 = arrayfun( @(f) mean(load(fullfile(f.folder, f.name))), allfd)';


%%% make table
% either way, it'll be useful to have it in a table
fd_table = table(id, fd_means);

%% Age
% get age from database, join to fd_table
ages = unique(db_query([...
    'select concat(id, ''_'', to_char(vtimestamp, ''yyyymmdd'')) as id, age ' ...
    ' from visit natural join visit_study natural join enroll ' ...
    ' where etype like ''LunaID'' ' ...
    ' and study like ''%Brain%'' '...
    ' and vtype like ''%scan%''']));

fd_age = join(fd_table,ages);
writetable(fd_age,'fd_ages.csv');

%% CSI spreadsheets + weird id lookup
% find all csi spreadsheets from victor/hoby
allsheets = dir('/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/*/SI1/spreadsheet.csv');
% make into a table with mrid and sheet (filename)
sheets = table(...
         regexp([allsheets.folder],'\d{8}[^/]*','match')',...
         arrayfun(@(x) fullfile(x.folder,x.name), allsheets,'UniformOutput',0), ...
         'VariableNames',{'mrid','sheet'});
% lookup 7TMRID to lunaid conversion using database
lunaid_7TID = unique(db_query([...
    'select '...
    ' luna.id as lunaid, '...
    ' mr.id as mrid, ' ...
    ' concat(luna.id, ''_'', substr(mr.id,1,8)) as id ' ...
    'from enroll as luna join enroll as mr on '...
    '  mr.etype=''7TMRID'' and luna.etype=''LunaID'' and '...
    '   mr.pid=luna.pid'...
    ]));
% fix poorly named csi spreadsheet to valid 7TMRID: 20180129 => 20180129Luna
sheets.mrid{strncmp('20180129',sheets.mrid,8)}='20180129Luna';
% join db lookup and sheet table together
sheet_id_all = outerjoin(sheets, lunaid_7TID, 'Key','mrid','Type','Left');
% we only want what has a spreadsheet and an id we can work with
sheet_id = sheet_id_all(~arrayfun(@(x) isempty(x{1}), sheet_id_all.lunaid),{'lunaid','id','sheet'});
% but we should track missing, so we can fix
regexp(...
    [sheet_id_all.sheet{arrayfun(@(x) isempty(x{1}), sheet_id_all.lunaid)}],...
    '\d{8}[^/]*','match')
% 20180216Luna1 exists? 11451_20180216

%% CSI Values
%%% for each row, find roi files asccoated with sheet and read both in
%%% then threshold on various combinations of tissue, gm, and crlb

% how to threshold inv crlb value
crlb_thres=@(x) (1 ./ x) <= 20;
tissue_thres = .6;
gm_thres = .6;
thal_thres = .6;
care_about = {'GABA','Glu'}; % which MRSI values in the sheet to look at

clear smry_metric % we build this itertively, so get rid of any hold out
for row=1:height(sheet_id)
    csi_csv=sheet_id.sheet{row};
    % read in spreadsheet into struct of matricies
    csivals = SI1_to_nii(csi_csv,[],[]);
    
    % csi rois are in this folder
    csi_roi_dir = ...
        sprintf('/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/MRSI/2d_csi_ROI/',...
            sheet_id.id{row});
        
    % try to read max tissue and fraction gm
    % if the files dont exist (try failed) we use Inf everywhere
    try 
        tissue_file = strtrim(ls(fullfile(csi_roi_dir,'*_MaxTissueProb_FlipLR')));
        tissue=read_in_2d_csi_mat(tissue_file);
        gm=read_in_2d_csi_mat(strtrim(ls(fullfile(csi_roi_dir,'*_FractionGM_FlipLR'))));
        thal=read_in_2d_csi_mat(strtrim(ls(fullfile(csi_roi_dir,'*_csivoxel_FlipLR.THA'))));
    catch
        tissue=Inf(24,24);
        gm=Inf(24,24);
        thal=Inf(24,24);
    end

    %%% whats going on with just the tissue probabilities
    tissue_i = tissue>tissue_thres;
    smry_metric(row).inTissue_n = nnz(gm(tissue_i));
    smry_metric(row).gmRatInTissue_Mean = mean(gm(tissue_i));
    
    %%% cre doesn't change
    crlb_cre_thres  = crlb_thres(csivals.Cre_SD_inv);
    
    smry_metric(row).csidir = csi_roi_dir;
    
    % for each roi
    for roi=care_about
        
        % variables
        roi=roi{1}; % get roi as a string instead of cell
        val = csivals.([roi '_Cre']);     % get roi ratio with Cre
        crlb = csivals.([roi '_SD_inv']); % and get crlb (denoted as SD by MR)
        
        % threshold indecies and values
        crlb_t  = crlb_thres(crlb);
        crlb_i = crlb_t & crlb_cre_thres;
        i = crlb_i & tissue_i;
        thal_i = thal_thres > .6;
        thal_i = thal > thal_thres;
              
        
        smry_metric(row).id = sheet_id.id(row);
        %%% summary calculations
        % counts
        smry_metric(row).([roi '_crlb_n'])    = nnz(crlb_i);
        smry_metric(row).([roi '_tissue_n'])  = nnz(tissue_i);
        smry_metric(row).([roi '_n'])         = nnz(i);
        % GM
        smry_metric(row).([roi '_GMratMean']) = mean(gm(i));
        smry_metric(row).([roi '_inGM_n'])    = nnz(val(i & gm > gm_thres) );
        smry_metric(row).([roi '_inGM_Mean']) = mean(val(i & gm > gm_thres) );
        % roi value
        smry_metric(row).([roi '_Mean'])      = mean(val(i));
        smry_metric(row).([roi '_std'])       = std(val(i));
        % crlb
        smry_metric(row).([roi '_CRLB'])      = mean( 1 ./ crlb(i));
        smry_metric(row).([roi '_allCRLB']) = mean( 1 ./ crlb(crlb < 999 & crlb~=0));
        % thalamus
        smry_metric(row).([roi '_thal_Mean']) = mean(val(i & thal_i));
        smry_metric(row).([roi '_thal_n'])    = nnz(thal_i);
        smry_metric(row).([roi '_thal_gm']) = mean(gm(i & thal_i));
    end
end

%% put it all together 
% all tables joined into one, saved out as csv
all_measures = outerjoin(...
               join(sheet_id,...
                    struct2table(smry_metric)),...
               fd_age,...
               'Type','Left');
writetable(all_measures,'all_measures_20190109.csv')