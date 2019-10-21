function [ funciones ] = read_file_by_lines( filename )
%READ_FILE_BY_LINES Reads a multilined file and returns a string with the
%file lines.
%   Reads a multilined file and returns a string with the
%   file lines.
    fileID = fopen(filename,'r');
    str = '';
    func= '';
    stage= '';
    funciones=cell(0);
    
    i=1;
    
    tline = fgetl(fileID);
    if(tline(1)=='%')
        stage=tline(2:end);
        tline=fgetl(fileID);
        tline=fgetl(fileID);
    end
    input_variables = cell(0);
    while ischar(tline)
        if(isempty(tline))
            tline=fgetl(fileID);
        end
        
        split_tline = strsplit(tline, '|');
        if isequal(str,'') && isequal(func,'')
            str = split_tline(1);
            func = split_tline(2);
        else
            str{length(str)+1} = split_tline{1};
            func{length(func)+1} = split_tline{2};
        end
        
        aux = cell(length(split_tline)-2, 2);
        for j = 2:length(split_tline)-1
            var = strsplit(split_tline{j+1}, '=');
            aux{j-1,1} = var{1};
            if length(var) == 2
                aux{j-1,2} = var{2};
            else
                aux{j-1,2} = '';
            end
        end
        input_variables{i} = aux;
        tline = fgetl(fileID);
        if(isempty(tline))
            tline=fgetl(fileID);
        end
        if(tline(1)=='%')
                if(isempty(funciones))
                    funciones.st{1}=stage;
                    funciones.mfiles{1}=func;
                    funciones.desc{1}=str;
                    funciones.input_var{1}=input_variables;
                else
                    funciones.st{end+1}=stage;
                    funciones.mfiles{end+1}=func;
                    funciones.desc{end+1}=str;
                    funciones.input_var{end+1}=input_variables;
                end
                stage=tline(2:end);
                i=0;
                tline=fgetl(fileID);          
                str = '';
                func= '';
        end
        i=i+1;
    end
    if(isempty(stage))
        funciones.mfiles=func;
        funciones.desc=str;
        funciones.input_var=input_variables;
    else
        funciones.st{end+1}=stage;
        funciones.mfiles{end+1}=func;
        funciones.desc{end+1}=str;
        funciones.input_var{end+1}=input_variables;
    end
    fclose(fileID);
end

