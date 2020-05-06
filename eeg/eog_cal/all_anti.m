allsubjs = regexp(find_bdf('#cal'),'\d{5}_\d{8}', 'match');
% data = cellfun(@(subjc) score_anti(subjc{1}), allsubjs)
data=[];
for subjc =allsubjs'
  subj=subjc{1}{1}
  try
    d = score_anti(subj);
  catch
   continue
  end
  data=[data;d];
end

% save all combined to .mat and to .csv
datatable = array2table(data);
datatable.Properties.VariableNames = {'LunaID','ScanDate','Trial','XDAT','Latency','Correct','meanEOGslope', 'velDispSlope','calR2', 'calSlope'};
save('eeg_anti.mat', 'datatable');
writetable(datatable,'eeg_anti.csv');
