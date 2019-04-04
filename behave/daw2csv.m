% 20180910 - WF 
%   read in daw task mat file and create csv file in Hera project directory
%
% run like:
%  matlab -r 'try,daw2csv,end;quit'
sdir='/Volumes/Hera/Projects/7TBrainMech/subjs/';
for t=dir('/Volumes/L/bea_res/Data/Temporary Raw Data/7T/1*_2*/*_task.mat')'
   mat=[t.folder,'/',t.name];
   a=load(mat);
   t=table(repmat({a.name},200,1),a.choice1',a.choice2',a.state',a.money');
   t.Properties.VariableNames = {'id' 'choice1' 'choice2' 'state','money'};
   out=fullfile(sdir,a.name,'daw',['daw_' a.name '.txt']);
   disp(out);
   mkdir(fileparts(out));
   writetable(t,out);
end

