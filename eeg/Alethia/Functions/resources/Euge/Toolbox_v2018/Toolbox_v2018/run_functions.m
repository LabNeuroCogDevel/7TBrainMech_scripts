function [data]= run_functions(handles)
data=handles.dat;
if(isfield(data,'EEG'))
    output=data.EEG;
else
    output='';
end
for k = 1:length(handles.dat.functions_to_run)
        function_k = handles.dat.functions_to_run(k);
        f = str2func(function_k.mfile);
        inputs = function_k.input(:,1);
        arguments = function_k.params;
        log_to_file(function_k.mfile,inputs, arguments, data.path_to_save);
        if ~isempty([arguments{:}])
            arguments{end+1}=output;
            arguments{end+1}=data;
            [data] = f(arguments{:});
        else
            [data] = f(data);
        end
end
