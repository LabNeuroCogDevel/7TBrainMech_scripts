function [inputs,answers]=input_dialog_custom(handles,inputs)
clear Format Prompts DefAns answers
Format=struct();
Prompts={};
DefAns={};
Prompts=inputs(:,1);
DefAns=inputs(:,2);
%Formats(1).style='edit';
for k=1:length(inputs(:,1))
    Format(k).style='edit';
    Format(k).format='text';
    %Format(k).size=-1;
    Format(k).labelloc='topleft';
    %Prompts{k}=inputs(k,1);
    %DefAns{k}=inputs(k,2);
    if(strfind(inputs{k,1},'*'))
        inputs{k,1}=inputs{k,1}(2:end);
        Prompts{k}=sprintf('Browse %s',inputs{k,1});
        Format(k).format='file';
        %Formats(k).type='button';
        if(~exist(DefAns{k},'file'))
            DefAns{k}=pwd;
        end
%         str1='*';
%         srt2='Browse file';
%         func_handle=@uigetfile;
        %Formats(k).callback=@(hObject,event,ctrls,i)browse_path_to_files();

    elseif(strfind(inputs{k,1},'~'))
        inputs{k,1}=inputs{k,1}(2:end);
        Prompts{k}=sprintf('Browse %s',inputs{k,1});
        Format(k).format='dir';
        %Formats(k).type='button';
%         Prompts{k+1}='Current/default path:';
%         Formats(k+1).type='edit';
        if(strcmp(inputs{k,1},'path_to_save'))
            if(isfield(handles.dat,'path_to_save'))
                DefAns{k}=handles.dat.path_to_save;
            end;
        elseif(strcmp(inputs{k,1},'path_to_data'))
            if(isfield(handles.dat,'path_to_data'))
                DefAns{k}=handles.dat.path_to_data;
            end
        end
        if(~isdir(DefAns{k}) || isempty(DefAns{k}))
            DefAns{k}=pwd;
        end
%        DefAns{k+1}=pwd;
        %str='Select folder';
        %Formats(k).callback=@(ctrls,ind)browse_path_to_save(ctrls,ind);
    end
    Options.AlignControls= 'on';
    Options.Interpreter = 'none';
end
[answers] = inputsdlg(Prompts,'Inputs',Format',DefAns,Options);

        
    
        
