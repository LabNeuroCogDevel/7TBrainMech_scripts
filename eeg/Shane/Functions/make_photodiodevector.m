function [micromed_time, mark]=make_photodiodevector(EEG)

%
% [trial_time]=make_photodiodevector(EEG)
%
% make_photodiodevector gives the photodiode time vector
% srate is the sampling rate
clear mark 
clear micromed_time
mark = nan(size(EEG.event));

for i=1:max(size(EEG.event))
    micromed_time(i)=EEG.event(i).latency;
    
    if class(EEG.event(i).type) == "char"
        EEG.event(i).type = str2num(EEG.event(i).type);

        if isempty(EEG.event(i).type)
            EEG.event(i).type = EEG.event(i).edftype; 
        end

        mark(i)=EEG.event(i).type;


        % if isempty(EEG.event(i).edftype)
        %     EEG.event(i).edftype = EEG.event(i-1).edftype; 
        % end
        % mark(i)=EEG.event(i).edftype;
        
    else
        mark(i)=EEG.event(i).type;
        mark(i) = mark(i) - min(mark);
  
    end
   
end

mark(mark>65000) = 0;

micromed_time=micromed_time/EEG.srate;