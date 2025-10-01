allsubjs = regexp(find_bdf('#cal'),'\d{5}_\d{8}', 'match');
% data = cellfun(@(subjc) score_anti(subjc{1}), allsubjs)
data=[];
error_mat = {};
for subjc =allsubjs'
  subj=subjc{1}{1}
  try
    d = score_anti(subj);
    if iscell(d)
        error_mat{end+1,:} = d;
        continue
    end
  catch e
      disp(e)
   continue
  end
  data=[data;d];
end

% save all combined to .mat and to .csv
currentdate = datetime();
currentdate.Format = "yyyyMMdd";
datatable = array2table(data);
datatable.Properties.VariableNames = {'LunaID','ScanDate','Trial','XDAT','Latency','Correct','meanEOGslope', 'velDispSlope','calR2', 'calSlope','trialOnsetIndex','dropReason'};
savename_mat = sprintf('eeg_anti_%s.mat',currentdate);
savename_csv = sprintf('eeg_anti_%s.csv',currentdate);
save(savename_mat, 'datatable');
writetable(datatable,savename_csv);
