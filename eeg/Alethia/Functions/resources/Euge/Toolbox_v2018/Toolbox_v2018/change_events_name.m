function [ EEG ] = change_events_name( original_names, new_names, EEG )
%CHANGE_LABEL_NAME Changes the name of the events.
%   This functions is mainly intended to change event names to number which
%   is what Python's mne understand and then change them back if needed.
    if length(original_names) ~= length(new_names)
        msgbox('Original names and new names must have the same length.','Error')
        return
    end
    for j = 1 : size(EEG.event,2)
        o_type = EEG.event(j).type;
        n_type = new_names(get_first_coincidence(original_names',o_type));
        if iscell(n_type)
            n_type = strjoin(n_type);
        end
        EEG.event(j).type = n_type;
    end
    for j = 1 : size(EEG.epoch,2)
        o_type = EEG.epoch(j).eventtype;
        n_type = new_names(get_first_coincidence(original_names',o_type));
        if iscell(n_type)
            n_type = strjoin(n_type);
        end
        EEG.epoch(j).eventtype = n_type;
    end
    for j = 1 : size(EEG.urevent,2)
        o_type = EEG.urevent(j).type;
        n_type = new_names(get_first_coincidence(original_names',o_type));
        if iscell(n_type)
            n_type = strjoin(n_type);
        end
        EEG.urevent(j).type = n_type;
    end
end

