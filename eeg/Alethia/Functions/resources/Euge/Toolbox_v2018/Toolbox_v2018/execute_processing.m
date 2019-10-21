function [ output, data ] = execute_processing( handles)
%GET_FIRST_COINCIDENCE Summary of this function goes here
%   Detailed explanation goes here
    addpath(genpath(fullfile(handles.data.ieeglab_path,'processing')));
    output = handles.data.epoched_data;
    data = handles.data;
    for i = 1:length(handles.data.processing_functions)
        processing_function = handles.data.processing_functions{i};
        if(processing_function.str(1)==' ')
            processing_function.str=processing_function.str(2:end);
        end
        f = str2func(processing_function.str);
        arguments = processing_function.params;
        inputs = handles.data.processing_input{processing_function.pos};
        log_to_file(processing_function.str, inputs(2:end,1), arguments, data.path);
        if ~isempty([arguments{:}])
            arguments{end+1} = output;
            arguments{end+1} = data;
            [output, data] = f(arguments{:});
        else
            [output, data] = f(output, data);
        end
    end
end

