function all_ppt_table = score_all_habit_anti()
% 20260714WF/VD - copied out of eog_ec_playground.m
%% score all sessions, all ppts
anti_glob = '/Volumes/Hera/Raw/EEG/Habit/1*_2*/*dr*.bdf'; % dr = dollar reward. sometimes *dr_run1.bdf
anti_files = dir(anti_glob);
%subjinfo([1:2,159],:)=[]; % skip . and .. (not needed will catch in dr file); drop 159

calstring = '*_eyecal.bdf';

for d = 1:size(anti_files)
    drfile = fullfile(anti_files(d).folder, anti_files(d).name);
    thiscal_glob = fullfile(anti_files(d).folder, calstring);
    calfile = dir(thiscal_glob);
    
    if isempty(calfile)
        fprintf('ERROR: NO CALFILE for idx %d like %s\n', d, thiscal_glob)
        continue
    end
    
    calname = fullfile(calfile.folder, calfile.name);
    

   [~,basename,~] = fileparts(drfile);
   outfile = fullfile('habitstudy_anti_trial_data', [ basename '.csv']);
   
   % TODO: skip if outfile exists. read it in instead
   %       watchout for extra 'fname' column already in output file
   try
      [all_tinfo{d},all_ppt_output{d}] = score_session(drfile, calname, CSVOutputFile=outfile);
   catch e
      disp(e)
      continue
   end
   all_ppt_output{d} = array2table(all_ppt_output{d});
   all_ppt_output{d}.Properties.VariableNames = {'lunaid', 'vdate', 'lat', 'score', 'stim_chan_code'};
   all_ppt_output{d}.fname = repmat(drfile, height(all_ppt_output{d}), 1);
   
   %for tinfo= all_tinfo{d}
   %    %Get lunaid and visit date
   %    matches = regexp(drfile,'\d{5}_\d{8}','match');
   %    splitstr=split(matches{1}, '_');
   %    lunaid = splitstr{1};
   %    vdate = splitstr{2};
   %
   %    tinfo=tinfo{1} % item is still a cell. extract
   %    %plot_tinfo(tinfo)
   %    %hgexport(gcf, sprintf('/tmp/%s_%s_%d_tinfo.png',lunaid, vdate, tinfo.trial_i));
   %end
end

%% Convert all_ppt_output 1x157 cell array to table
all_ppt_table=vertcat(all_ppt_output{:});


% Write the table to a CSV file
% writetable(all_ppt_table,'all_ppt_table.csv')
writetable(all_ppt_table,'habit_anti_all_ppt_table.csv')
end

