function EEG = lncd_triggers(EEG)
    %% LNCD_TRIGGERS - update EEG with adjusted ttl trigger values (baseline removed)

    % using pop_editeventvals w/'changefield' 
    % > 'changefield' - {num field value} Insert the given value into the specified 
    % >                 field in event num. (Ex: {34 'latency' 320.4})
    % TODO:
    % compare to
    %   EEGOUT = pop_editeventvals( EEG, 'key1', value1, ...
    %                                    'key2', value2, ... );

    %% time (secs), ttl value
    % (code from alethia)
    [micromed_time, mark] = make_photodiodevector(EEG);
    % see
    %   plot([micromed_time;micromed_time],[-100;0],'r')
    %   figure(5);plot(micromed_time ,mark ,'r*')
    
    % remove baseline and very high values
    mark = fix_status_channel(mark);

    %% iteritvely update events
    for ttlval=unique(mark)
        mmark = find(mark==ttlval);
        if isempty(mmark), continue, end
        for j = 1:length(mmark)
            mark_sort_idx = mmark(j);
            EEG = pop_editeventvals(EEG, 'changefield', {mark_sort_idx 'type' ttlval});
        end
    end
end