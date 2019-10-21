function [ output_args ] = load_handles_toolbox(handles)

    if isfield(handles.dat,'project_file_name')
            set(handles.Current_Project_Label,'Visible','On');
            set(handles.Project_file_text,'Visible','On');
            set(handles.Project_file_text, 'String', handles.dat.project_file_name);
    end

    if(isfield(handles.dat,'data_file_name'))
    set(handles.Data_File_Label,'Visible','On');    
    set(handles.Data_file_text,'Visible','On');
    set(handles.Data_file_text,'String',handles.dat.data_file_name);
    end
   
    if(isfield(handles.dat,'path_to_files'))
    set(handles.Data_File_Label,'Visible','On');    
    set(handles.Data_file_text,'Visible','On');
    [~,folder_name]=fileparts(handles.dat.path_to_files);
    set(handles.Data_file_text,'String',folder_name);
    end

    if(isfield(handles.dat,'technique_path'))
        if(exist(fullfile(handles.dat.technique_path,'\more_functions.txt'),'file') && strcmp(handles.More.Visible,'off'))
    
        [more_functions_struct] = read_file_by_lines(fullfile(handles.dat.technique_path,'\more_functions.txt'));
        more_functions_desc=more_functions_struct.desc;
        more_functions_mfiles=more_functions_struct.mfiles;
        more_functions_inputs=more_functions_struct.input_var;

        handles.dat.more_functions=more_functions_struct;

        set(handles.More,'Visible','on');
        if(isdir(fullfile(handles.dat.technique_path,'\More')))
        addpath(genpath(fullfile(handles.dat.technique_path,'\More')));
        else
            error('The required folder was not found');
        end
        for k=1:length(more_functions_struct.mfiles)
            func_handle=str2func(more_functions_struct.mfiles{k});
            inputs=more_functions_inputs{k};
            uimenu(handles.More,'Label',more_functions_desc{k},'Callback',func_handle);
        end

        end
        set(handles.Techniques_List,'Visible','Off');
        set(handles.OK_button,'Visible','Off');
        set(handles.select_technique_text,'Visible','Off');
        
        set(handles.Select_function_text,'Visible','On');
        set(handles.Functions_pop_up_menu,'Visible','On');
        set(handles.Functions_pop_up_menu,'String',handles.dat.current_functions_list.desc);
        
        if(isfield(handles.dat,'stage'))
            set(handles.function_group_list_box,'Visible','On');
            set(handles.function_group_list_box,'String',handles.dat.all_stages);
            set(handles.functions_group_text,'Visible','On');
            set(handles.Functions_pop_up_menu,'Visible','On');
            set(handles.Functions_pop_up_menu,'String',handles.dat.all_functions.desc{handles.dat.stage_pos});
        end
           set(handles.Delete_button,'Visible','On');
           set(handles.Add_button,'Visible','On');
           set(handles.Edit_button,'Visible','On');
           set(handles.Remove_all_button,'Visible','On');
           set(handles.Run_button,'Visible','On');
           set(handles.Functions_List,'Visible','On');
           set(handles.Functions_pop_up_menu,'Visible','On');
           set(handles.Functions_pop_up_menu,'String',handles.dat.current_functions_list.desc);
    end
      
    if isfield(handles.dat,'functions_to_run')
        set(handles.Functions_List,'Value',size(handles.dat.functions_to_run,2));
        if isempty(handles.dat.functions_to_run)
            set(handles.Functions_List,'String','');
        else
            set(handles.Functions_List,'String', {handles.dat.functions_to_run.str});
        end
    end