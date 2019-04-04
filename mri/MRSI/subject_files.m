function [subj] = subject_files(ld8_or_mrid)
%subject_files - get structure of subject files


%% what id did we give, can we find the other one?
if( length(ld8_or_mrid) == 5+1+8 && ld8_or_mrid(6) == '_' )
    % is lunaid, need to find mrid
    subj_id=ld8_or_mrid;
    q=db_query([...
        'select mr.id as id, mr.pid '...
        ' from enroll as luna join'...
        '      enroll as mr on' ...
        '   mr.pid     =    luna.pid   and '...
        '   mr.etype   like ''7TMRID'' and '...
        '   luna.etype like ''LunaID'' and '...
        sprintf('luna.id = ''%s''',subj_id(1:5))]);
    if height(q) == 0
        warning('no 7TMRID for %s', subj_id)
        subj = [];
        return
    end
    mrid=q.id{1};
else
    mrid=ld8_or_mrid;
    query = [...
        'select '...
        ' concat(luna.id,''_'',substr(mr.id,0,9)) as id, '...
        ' mr.pid '...
        ' from enroll as luna join'...
        '      enroll as mr on' ...
        '   mr.pid     =    luna.pid   and '...
        '   mr.etype   like ''7TMRID'' and '...
        '   luna.etype like ''LunaID'' and '...
        sprintf('mr.id = ''%s''', mrid)];
    q=db_query(query);
    if istable(q) && height(q) == 0 
        error('no luna_date id for %s', mrid)
    elseif ~istable(q)
        disp(q)
        disp(query)
        mrid,
        warning('bad 7t mrid query for 7t id %s', mrid)
        subj=[];
        return
    end
    subj_id=q.id{1};

end
if(height(q) > 1)
    warning('have more than one match for %s, picking first!', ld8_or_mrid)
end
% store pid for age + sex lookup later
pid=q.pid(1);

%% hard code duplicate lunaid resolve
if strncmp(subj_id,'11390',5)
    warning('looking for id 11390 but is 7T 11665 (duplicated lunaid)');
    subj_id = ['11665' subj_id(6:end)];
end
    

%% what files do we care about?
%subj.data_dir=sprintf('/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/atlas_roi',subj_id);
subj.roi_mprage=sprintf('/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/roi_mprage.nii.gz',subj_id);
subj.slice_txt=sprintf('/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/MRSI/scout_slice_num.txt',subj_id);
subj.filename_scout=sprintf('/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/MRSI/scout.nii',subj_id);
subj.subj_mprage=sprintf('/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/ppt1/mprage.nii.gz',subj_id);
subj.csi = sprintf('/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/%s/SI1/spreadsheet.csv', mrid);
% get slice number for files dependent on it
slice_num = NaN;
if exist(subj.slice_txt,'file'), slice_num = load(subj.slice_txt); end
% get frac gm
subj.fracgm_file = sprintf('/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/MRSI/2d_csi_ROI/%d_FractionGM_FlipLR', subj_id, slice_num);


% csi could be in two other places
if ~exist(subj.csi,'file') 
    csidir = dir(sprintf('/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/*/%s/SI1/spreadsheet.csv', mrid)); 
    if ~isempty(csidir)
        subj.csi = fullfile(csidir(1).folder, csidir(1).name);
    end
end


%% do we have all files?
haveall=1;
for f=fieldnames(subj)'
    this_file = subj.(f{1});
    if ~exist(this_file,'file')
        warning('%s/%s: missing %s file %s', subj_id, mrid, f{1}, this_file)
        haveall=0;
    end
end
subj.have_all_files = haveall;



%% populate not file fields
% ids
subj.mrid = mrid;
subj.subj_id = subj_id;
% add slice to struct
subj.scout_slice = slice_num;

% gmfrac -- do this eslewhere instead -- expensive to load up matrices?
% if exists(subj.fracgm_file,'file')
%     subj.fracgm = read_in_2d_csi_mat(subj.fracgm_file);
% else
%     subj.fracgm = NaN;
% end

%% get age and sex

query= [ ...
' select  dob, sex '...
' from person where pid = ' num2str(pid)];
q=db_query(query);
if ~istable(q), disp(pid), error('cannot find pid %d in db!',pid); end
subj.sex=q.sex{1};
subj.dob=q.dob{1};

end

