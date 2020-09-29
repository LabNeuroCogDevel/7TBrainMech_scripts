function file_status()
   root=hera('Raw/EEG/7TBrainMech/');
   mi = getIds('#mgs');
   ci = getIds('#cal');

   missing.cal = setdiff(mi,ci);
   missing.mgs = setdiff(ci,mi);
   for ms = fieldnames(missing)'
       ms=ms{1};
       if ~isempty(missing.(ms))
           for ld=missing.(ms)
               fprintf('missing %s in %s\%s:\n',ms, root,ld{1})
               ls([root,ld{1}])
           end
       end
   end
end

function um = getIds(taskname)
  extractID = @(x) regexp(x,'\d{5}+_\d{8}+','once','match');
  fm = find_bdf(taskname);
  m = cellfun(extractID,fm,'UniformOutput',0);
  [um, im] = unique(m, 'first');
  missing = not(ismember(1:numel(m),im));
  duplicatedID = find(ismember(m,m(missing)));
  if ~isempty(duplicatedID)
      fprintf("duplicated ids in %s files:\n", taskname)
      disp(fm(duplicatedID'))
  end
end
