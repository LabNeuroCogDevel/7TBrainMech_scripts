%%%% script to run r2prime 

%% find shared subjects between mMR and 7T 
st  = dir('/Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/prepro*');
mmr = dir('/Volumes/Phillips/mMR_PETDA/subjs/1*_2*/r2prim*');

% basename of the folder (lunaid_date) -> grab first after split on _ -> lunaid
extract_id = @(s) cellfun(@(y) y(1), ...
            cellfun(@(x) strsplit(basename(x),'_'), ...
            {s.folder},'Un', 0));
% index where item in 7t subjlist is anywhere in mmr list
shared_in_st = st(ismember(extract_id(st),extract_id(mmr)));
% get those ids
ids_7t = cellfun(@basename,{shared_in_st.folder},'Un',0);

% show it off
disp(ids_7t)

%% run for all
for id=ids_7t
   try
      r2prime_mc(id{1});
   catch e
      warning('failed to run %s: %s', id{1}, e.message)
   end
end

