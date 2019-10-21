function [ output, data ] = execute_epoching( handles)
%GET_FIRST_COINCIDENCE Summary of this function goes here
%   Detailed explanation goes here
    addpath(fullfile(handles.data.ieeglab_path,'epoching'));
    output = handles.data.preprocessed_data;
    data = handles.data;
    f = str2func(handles.data.epoching_function.str);
    if ~isfield(handles.data.epoching_function,'params')
        input = handles.data.epoching_input{handles.data.epoching_function.pos};
        if ~isempty(input(:,1))
            answer = dynamic_inputdlg(input(:,1),'Epoching Parameters', 1, input(:,2));
            if ~isempty(answer)
                handles.data.epoching_function.params = answer;
                guidata(handles.epoching_select_menu,handles);
            else
                return
            end
        else
            handles.data.epoching_function.params = {};
            guidata(hObject,handles);
        end
    end
    arguments = handles.data.epoching_function.params;
    inputs = handles.data.epoching_input{handles.data.epoching_function.pos};
    log_to_file(handles.data.epoching_function.str, inputs(:,1), arguments, data.path);
    if ~isempty([arguments{:}])
        arguments{end+1} = output;
        arguments{end+1} = data;
        [output, data] = f(arguments{:});
    else
        [output, data] = f(output, data);
    end

end

