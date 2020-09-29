function bdf_files = find_bdf(taskname,varargin)
%FIND_BDF  find bdf files for 7TBrainMech task (synced from box)
% USAGE:
%   find_bdf('MGS')
%   find_bdf({'EOG','eye'})
%   find_bdf('MGS','subjs',{'11676','10195_20180201'})
% NB: "#cal" and "#mgs" are special tasknames -- searches all variations

if isa(taskname,'char') && strcmp(taskname,'#cal')
   warning('searching for eyecal variations (extend in find_bdf)')
   taskname={'Cal','cal','CAL','EOG'};
end
if isa(taskname,'char') && strcmp(taskname,'#mgs')
   warning('searching for mgs task and variations (extend in find_bdf)')
   taskname={'mgs','MGS'};
end
if isa(taskname,'char') && strcmp(taskname,'#anti')
   warning('searching for anti task and variations (extend in find_bdf)')
   taskname={'Anti','ANTI', 'anti'};
end

%% cell of tasks => recursive calls to find_bdf
% get each task individually, then combine
if(isa(taskname,'cell'))
    alltasks  = cellfun(@(x) find_bdf(x,varargin{:}), taskname, 'UniformOutput',0);
    bdf_files = unique(vertcat(alltasks{:}));
    return
end

%% figure out what to search for
% taskname could be 
%  1) full path to a single subject (or own glob)
%  2) specific glob for all subjects
%  3) a simple task pattern
root=hera('Raw/EEG/7TBrainMech/');
if contains(taskname,'/')
    if ~ contains(taskname,root)
        warning(['you gave a path but it doesnt include the root dir (' ...
            root ')']); 
    end
    searchpath=taskname;
elseif contains(taskname,'*')
    warning('using your glob instead of default');
    searchpath=fullfile(root,'1*_2*',taskname);
else
    searchpath=fullfile(root,'1*_2*',['*' taskname ]);
end
% add extension if needed
if isempty(regexp(taskname,'.bdf$','once'))
 searchpath=[searchpath '*.bdf'];
end
    

%% get all files
bdf_files = dir(searchpath);
bdf_files = arrayfun(@(x) fullfile(x.folder,x.name), bdf_files, 'UniformOutput',0);

%% exclude known bad files
% remove 11716_20181130_eycal: bad file, fieldtrip cannot read
% added 20190108
exclude_list = {'/11716_20181130_eyecal.bdf'};
exclude = cellfun(@(e) contains(bdf_files,e), exclude_list,'UniformOutput',0);
exclude = sum(cell2mat(exclude),2) > 0;
bdf_files = bdf_files(~exclude);

%% limit to given 'subjs'
% get idex of 'subjects', look one past that
% use contains against each list
subjidx = find(cellfun( @(x) isa(x,'char') && strcmp(x,'subjs'), varargin));
if ~isempty(subjidx)
    subjlist=varargin{subjidx+1};
    subj_in_list = cellfun(@(subj) contains(bdf_files,['/' subj]), subjlist, 'UniformOutput', 0);
    list_idx = sum(cell2mat(subj_in_list),2) > 0;
    bdf_files = bdf_files(list_idx);
end


end

