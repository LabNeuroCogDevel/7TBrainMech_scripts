function [] = homogenizeChanLoc(setfiles,correction_cap_location,outpath)
[filepath,filename ,ext] =  fileparts((setfiles));

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename',[filename,ext],'filepath',filepath);
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
CL = importdata(correction_cap_location);
CL.n = CL.textdata(2:end-2,1);
CL.name = CL.textdata(2:end-2,2);

EEG_old  = EEG;
CL_old.name = {EEG_old.chanlocs.labels}';
CL_old.n = {EEG_old.chanlocs.urchan}';

if length(CL.name) ~= length(CL_old.name)
    error('subject %s does not have 64 channels', filename);
    
end

% TODO: probably not going to run correctly!!

differ = find(~strcmp(CL.name, CL_old.name)); 
for idealIDX = differ'
    previousIDX = find(strcmp(CL.name(idealIDX), CL_old.name));
    EEG.chanlocs(idealIDX) = EEG_old.chanlocs(previousIDX);        % update ChanLoc
    EEG.chanlocs(idealIDX).urchan  = idealIDX;                  % update number *maybe not mandatory
    EEG.data(idealIDX,:) = EEG_old.data(previousIDX,:);            % move data
    
end

EEG = pop_saveset( EEG, 'filename',filename, 'filepath',outpath);
