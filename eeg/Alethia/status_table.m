function tbl = status_table()
% STATUS_TABLE - create a status table and upload to google drive
% https://docs.google.com/spreadsheets/d/1uEyK-Gu86uCDr8KiKVEXlN0pSa9rFcR4DGxG3-gtVv8

    %% get fies
    setfiles = all_remarked_set('struct', true);
    lunaid = cellfun(@(x) x{1}, regexp({setfiles.name},'\d{5}_\d{8}','match'),'Un',0)';
    is128 = [setfiles.is128]';
    
    %% count channels after homogonize -- should all be 64, is not
    homog_channels = zeros(size(is128));
    for i=1:length(homog_channels)
      homog_channels(i)=0;
      f = file_locs(fullfile(setfiles(i).folder,setfiles(i).name));
      % nothing to do if we dont have the file
      if ~exist(f.epochClean, 'file')
          warning('no file %s',f.epochClean)
          continue
      end
      eeg = pop_loadset(f.epochClean);
      homog_channels(i) = size(eeg.data,1);
    end
    
    
    %% write status table and upload to google
    tbl = table(lunaid, is128, homog_channels);
    writetable(tbl,'status.csv')
    % gsheets is python script in /opt/ni_tools/lncdtools (in PATH on rhea)
    system('gsheets -a upload status.csv  -w 1uEyK-Gu86uCDr8KiKVEXlN0pSa9rFcR4DGxG3-gtVv8')
end