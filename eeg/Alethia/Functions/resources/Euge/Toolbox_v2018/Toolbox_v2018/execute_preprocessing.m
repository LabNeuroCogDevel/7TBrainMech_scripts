function [ output, data ] = execute_preprocessing( handles)
%GET_FIRST_COINCIDENCE Summary of this function goes here
%   Detailed explanation goes here
    addpath(fullfile(handles.data.ieeglab_path,'preprocessing'));
    if ~isfield(handles.data,'EEG')
        handles.data.EEG='';
    end
        output = handles.data.EEG;
        data = handles.data;
    for i = 1:length(handles.data.preprocessing_functions)
        preprocessing_function = handles.data.preprocessing_functions{i};
        f = str2func(preprocessing_function.str);
        arguments = preprocessing_function.params;
        inputs = handles.data.preprocessing_input{preprocessing_function.pos};
        log_to_file(preprocessing_function.str, inputs(:,1), arguments, data.path);
        if ~isempty([arguments{:}])
            arguments{end+1} = output;
            arguments{end+1} = data;
            [output, data] = f(arguments{:});
        else
            [output, data] = f(output, data);
        end
    end
end

