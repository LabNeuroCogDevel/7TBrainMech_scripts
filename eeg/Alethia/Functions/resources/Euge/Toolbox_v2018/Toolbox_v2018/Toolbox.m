function varargout = Toolbox(varargin)
% TOOLBOX MATLAB code for Toolbox.fig
%      TOOLBOX, by itself, creates a new TOOLBOX or raises the existing
%      singleton*.
%
%      H = TOOLBOX returns the handle to a new TOOLBOX or the handle to
%      the existing singleton*.
%
%      TOOLBOX('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TOOLBOX.M with the given input arguments.
%
%      TOOLBOX('Property','Value',...) creates a new TOOLBOX or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Toolbox_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Toolbox_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Toolbox

% Last Modified by GUIDE v2.5 06-Dec-2018 17:11:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Toolbox_OpeningFcn, ...
                   'gui_OutputFcn',  @Toolbox_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Toolbox is made visible.
function Toolbox_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Toolbox (see VARARGIN)

% Choose default command line output for Toolbox
clear data;
data=struct();

data.toolbox_path=fileparts(which('Toolbox'));

if(~exist(fullfile(data.toolbox_path,'Techniques'),'dir'))
    error('No Techniques folder found');
    delete(Toolbox);
    return;
end

techniques=dir(fullfile(data.toolbox_path,'Techniques'));
techniques_list={techniques(3:end).name};

[selection,ok]=listdlg('ListString',techniques_list,'PromptString','Select technique');

if(ok)
%set(handles.Techniques_List,'String',data.techniques_list);
    current_technique=techniques_list{selection};
else
    error('No technique was selected');
    return;
end

handles=setfield(handles,'dat',data);
handles.output = hObject;

%set(Toolbox,'Name',strcat('Selected technique:',' ',handles.dat.technique));
handles.Name=strcat('Technique: ',current_technique);

answer=questdlg('Do you want to add other toolbox?','Extra toolboxes','Yes','No','No');

while(strcmp(answer,'Yes'))
        extra_toolbox_path=uigetdir(handles.dat.toolbox_path,'Select folder');
        addpath(genpath(extra_toolbox_path));
        answer=questdlg('Do you want to add another toolbox?','Extra toolboxes','Yes','No','No');
end
    
if(exist(fullfile(handles.dat.toolbox_path,'Techniques',current_technique),'dir'))
    handles.dat.technique_path=fullfile(handles.dat.toolbox_path,'Techniques',current_technique);
    addpath(genpath(handles.dat.technique_path));
else return;
end

if(exist(fullfile(handles.dat.technique_path,'functions.txt')))
    [functions_struct] = read_file_by_lines(fullfile(handles.dat.technique_path,'functions.txt')); %codificar las etapas de análisis, si es que existieran. Ejemplo, poner un signo % delante para dividir la lista de funciones del txt
else
    error('The file functions.txt was not found in the current directory');
    return;
end

if(isfield(functions_struct,'st'))
    stages=functions_struct.st;
    for k=1:length(stages)
        if(~isdir(fullfile(handles.dat.technique_path,stages{k})))
            error('No %s folder found!',stages{k});
            return;
        end
    end
    handles.dat.all_stages=stages;
    handles.dat.all_functions.mfiles=functions_struct.mfiles;
    handles.dat.all_functions.desc=functions_struct.desc;
    handles.dat.all_functions.inputs=functions_struct.input_var;
%     set(handles.function_group_list_box,'Visible','On');
%     set(handles.functions_group_text,'Visible','On');
    set(handles.function_group_list_box,'String',stages);
    
    func=functions_struct.mfiles{1};
    desc=functions_struct.desc{1};
    inputs=functions_struct.input_var{1};
    handles.dat.stage=handles.dat.all_stages{1};
    handles.dat.stage_pos=1;
else
    func=functions_struct.mfiles;
    desc=functions_struct.desc;
    inputs=functions_struct.input_var;
end

% set(handles.Techniques_List,'Visible','Off');
% set(handles.Functions_List,'Visible','On');
% set(handles.OK_button,'Visible','Off');
% set(handles.select_technique_text,'Visible','Off');
% set(handles.Functions_pop_up_menu,'Visible','On');
% set(handles.Select_function_text,'Visible','On');
% set(handles.Add_button,'Visible','On');
% set(handles.Edit_button,'Visible','On');
% set(handles.Delete_button,'Visible','On');
% set(handles.Remove_all_button,'Visible','On');
set(handles.Functions_pop_up_menu,'String',desc);
% set(handles.Run_button,'Visible','On');

% if(exist(fullfile(handles.dat.technique_path,'\more_functions.txt'))==2 && strcmp(handles.More.Visible,'off'))
%     
%     [more_functions_struct] = read_file_by_lines(fullfile(handles.dat.technique_path,'\more_functions.txt'));
%     more_functions_desc=more_functions_struct.desc;
%     more_functions_mfiles=more_functions_struct.mfiles;
%     more_functions_inputs=more_functions_struct.input_var;
%     
%     handles.dat.more_functions=more_functions_struct;
%     
%     %set(handles.More,'Visible','On');
%     if(isdir(fullfile(handles.dat.technique_path,'\More')))
%     addpath(genpath(fullfile(handles.dat.technique_path,'\More')));
%     else
%         error('The required folder was not found');
%     end
%     for k=1:length(more_functions_struct.mfiles)
%         func_handle=str2func(more_functions_mfiles{k});
%         inputs=more_functions_inputs{k};
%         menu_item=uimenu(handles.More,'Label',more_functions_desc{k});
%         set(menu_item,'Callback',@(menu_item,evt)func_handle(inputs,handles));
%     end
%     
% end
% 
handles.dat.current_functions_list.desc=desc;
handles.dat.current_functions_list.mfiles=func;
handles.dat.current_functions_list.inputs=inputs;

load_handles_toolbox(handles);
guidata(hObject,handles);


% UIWAIT makes Toolbox wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = Toolbox_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in Techniques_List.
function Techniques_List_Callback(hObject, eventdata, handles)
% hObject    handle to Techniques_List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Techniques_List contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Techniques_List

handles.dat.current_technique=get_current_popup_string(hObject);
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function Techniques_List_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Techniques_List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
guidata(hObject,handles);

% --- Executes on button press in OK_button.
function OK_button_Callback(hObject, eventdata, handles)
% hObject    handle to OK_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%data=handles.dat;

handles.dat.technique=handles.dat.current_technique;

%set(Toolbox,'Name',strcat('Selected technique:',' ',handles.dat.technique));

answer=questdlg('Do you want to add other toolbox?','Extra toolboxes','Yes','No','No');

while(strcmp(answer,'Yes'))
        extra_toolbox_path=uigetdir(handles.dat.toolbox_path,'Select folder');
        addpath(genpath(extra_toolbox_path));
        answer=questdlg('Do you want to add another toolbox?','Extra toolboxes','Yes','No','No');
end
    

if(exist(fullfile(handles.dat.toolbox_path,'Techniques',handles.dat.technique),'dir'))
    handles.dat.technique_path=fullfile(handles.dat.toolbox_path,'Techniques',handles.dat.technique);
    addpath(genpath(handles.dat.technique_path));
else return;
end

if(exist(fullfile(handles.dat.technique_path,'functions.txt')))
    [functions_struct] = read_file_by_lines(fullfile(handles.dat.technique_path,'functions.txt')); %codificar las etapas de análisis, si es que existieran. Ejemplo, poner un signo % delante para dividir la lista de funciones del txt
else
    error('The file functions.txt was not found in the current directory');
    return;
end

if(isfield(functions_struct,'st'))
    stages=functions_struct.st;
    for k=1:length(stages)
        if(~isdir(fullfile(handles.dat.technique_path,stages{k})))
            error('No %s folder found!',stages{k});
            return;
        end
    end
    handles.dat.all_stages=stages;
    handles.dat.all_functions.mfiles=functions_struct.mfiles;
    handles.dat.all_functions.desc=functions_struct.desc;
    handles.dat.all_functions.inputs=functions_struct.input_var;
    set(handles.function_group_list_box,'Visible','On');
    set(handles.functions_group_text,'Visible','On');
    set(handles.function_group_list_box,'String',stages);
    
    func=functions_struct.mfiles{1};
    desc=functions_struct.desc{1};
    inputs=functions_struct.input_var{1};
    handles.dat.stage=handles.dat.all_stages{1};
    handles.dat.stage_pos=1;
else
    func=functions_struct.mfiles;
    desc=functions_struct.desc;
    inputs=functions_struct.input_var;
end

set(handles.Techniques_List,'Visible','Off');
set(handles.Functions_List,'Visible','On');
set(handles.OK_button,'Visible','Off');
set(handles.select_technique_text,'Visible','Off');
set(handles.Functions_pop_up_menu,'Visible','On');
set(handles.Select_function_text,'Visible','On');
set(handles.Add_button,'Visible','On');
set(handles.Edit_button,'Visible','On');
set(handles.Delete_button,'Visible','On');
set(handles.Remove_all_button,'Visible','On');
set(handles.Functions_pop_up_menu,'String',desc);
set(handles.Run_button,'Visible','On');

if(exist(fullfile(handles.dat.technique_path,'\more_functions.txt'))==2)
    
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
        func_handle=str2func(more_functions_mfiles{k});
        inputs=more_functions_inputs{k};
        menu_item=uimenu(handles.More,'Label',more_functions_desc{k});
        set(menu_item,'Callback',@(menu_item,evt)func_handle(inputs,handles));
    end
    
end

handles.dat.current_functions_list.desc=desc;
handles.dat.current_functions_list.mfiles=func;
handles.dat.current_functions_list.inputs=inputs;

load_handles_toolbox(handles);
guidata(hObject,handles);
% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
    handles = guidata(hObject);
    selection = questdlg('Do you want to save changes?', ...
	'Warning', ...
	'Yes','No','No');
    switch selection
        case 'Yes'
            if ~isfield(handles.dat,'project_path')
                [file_name, path] = uiputfile;
                if file_name
                    handles.dat.project_file_name = file_name;
                    handles.dat.project_path = path;
                else
                    return
                end
            end
            save_file(handles);
            delete(gcf)
        case 'No'
            delete(gcf)
    end

% --- Executes on selection change in Functions_pop_up_menu.
function Functions_pop_up_menu_Callback(hObject, eventdata, handles)
% hObject    handle to Functions_pop_up_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Functions_pop_up_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Functions_pop_up_menu

[handles.dat.current_function.str, handles.dat.current_function.pos] = get_current_popup_string(hObject);
handles.dat.current_function.mfile=handles.dat.current_functions_list.mfiles{handles.dat.current_function.pos};

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function Functions_pop_up_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Functions_pop_up_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Add_button.
function Add_button_Callback(hObject, eventdata, handles)
% hObject    handle to Add_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.dat.current_function.params = {};
orig_input = handles.dat.current_functions_list.inputs{handles.dat.current_function.pos};
if ~isempty(orig_input(:,1))
    [inputs,answers]=input_dialog_custom(handles,orig_input);

    if ~isempty(answers)
        handles.dat.current_function.params = answers;
        handles.dat.current_function.input=inputs;
        handles.dat.current_function.original_input=orig_input;
    else
        return
    end
end

if(~isfield(handles.dat,'functions_to_run') || isempty(handles.dat.functions_to_run))
    handles.dat.functions_to_run=struct(handles.dat.current_function);
else 
        handles.dat.functions_to_run(end+1) = struct(handles.dat.current_function);
end

set(handles.Functions_List,'String',{handles.dat.functions_to_run(:).str});
load_handles_toolbox(handles);

guidata(hObject,handles);



% --- Executes on button press in Edit_button.
function Edit_button_Callback(hObject, eventdata, handles)
% hObject    handle to Edit_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles.dat,'current_function_to_delete')
    current_function = handles.dat.functions_to_run(handles.dat.current_function_to_delete);
    if ~isempty(current_function.original_input(:,1))
        current_function.original_input(:,2)=current_function.params(:);
        [input,answers] = input_dialog_custom(handles,current_function.original_input);
        if ~isempty(answers)
            current_function.params = answers;
            current_function.input=input;
            handles.dat.functions_to_run(handles.dat.current_function_to_delete) = struct(current_function);
            guidata(hObject,handles)
        end
    end
end

load_handles_toolbox(handles);

guidata(hObject,handles);

% --- Executes on button press in Delete_button.
function Delete_button_Callback(hObject, eventdata, handles)
% hObject    handle to Delete_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles.dat,'current_function_to_delete')
    if ~isempty(handles.dat.functions_to_run(:))
        handles.dat.functions_to_run(:,handles.dat.current_function_to_delete) = [];
    end

     set(handles.Functions_List,'String',{handles.dat.functions_to_run(:).str});
end

load_handles_toolbox(handles);
guidata(hObject,handles);

% --- Executes on button press in Remove_all_button.
function Remove_all_button_Callback(hObject, eventdata, handles)
% hObject    handle to Remove_all_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

answer=questdlg('Do you want to remove all functions in the list?','Warning','Yes','No','No');

if(strcmp(answer,'Yes'))
    handles.dat.functions_to_run=struct.empty();
    set(handles.Functions_List,'String','');
end

 set(handles.Functions_List,'Value',1.0);
 guidata(hObject,handles);
        


function function_group_list_box_Callback(hObject, eventdata, handles)
% hObject    handle to function_group_list_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of function_group_list_box as text
%        str2double(get(hObject,'String')) returns contents of function_group_list_box as a double

[handles.dat.stage, handles.dat.stage_pos]=get_current_popup_string(hObject);

handles.dat.current_functions_list.mfiles=handles.dat.all_functions.mfiles{:,handles.dat.stage_pos};
handles.dat.current_functions_list.desc=handles.dat.all_functions.desc{:,handles.dat.stage_pos};
handles.dat.current_functions_list.inputs=handles.dat.all_functions.inputs{:,handles.dat.stage_pos};

set(handles.Functions_pop_up_menu,'Value',length(handles.dat.current_functions_list));
set(handles.Functions_pop_up_menu,'String',handles.dat.current_functions_list.desc);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function function_group_list_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to function_group_list_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
guidata(hObject,handles);


% --- Executes on selection change in Functions_List.
function Functions_List_Callback(hObject, eventdata, handles)
% hObject    handle to Functions_List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Functions_List contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Functions_List
handles.dat.current_function_to_delete = get(hObject,'Value');
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function Functions_List_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Functions_List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function File_button_Callback(hObject, eventdata, handles)
% hObject    handle to File_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Load_Project_Callback(hObject, eventdata, handles)
% hObject    handle to Load_Project (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file_name, path] = uigetfile('*.mat');
if file_name
    handles = load_file( file_name, path, handles);
    load_handles_toolbox(handles);
    guidata(hObject,handles)
end


% --------------------------------------------------------------------
function Save_Project_Callback(hObject, eventdata, handles)
% hObject    handle to Save_Project (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file_name, path] = uiputfile('*.mat','Save Workspace As');
if file_name
    handles.dat.project_file_name = file_name;
    handles.dat.project_path = path;
    save_file( handles);
end

load_handles_toolbox(handles);

guidata(hObject,handles);


% --- Executes on button press in Run_button.
function Run_button_Callback(hObject, eventdata, handles)
% hObject    handle to Run_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(~isfield(handles.dat,'path_to_save'))
    path_to_save=uigetdir(handles.dat.toolbox_path,'Select folder to save results');
    if(isdir(path_to_save))
        handles.dat.path_to_save=path_to_save;
    else
        msgbox('No path to save was selected');
        return;
    end
end
    

[data]=run_functions(handles);


guidata(hObject,handles);

% --------------------------------------------------------------------
function More_Callback(hObject, eventdata, handles)
% hObject    handle to More (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Load_Callback(hObject, eventdata, handles)
% hObject    handle to Load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Load_Single_Subject_Callback(hObject, eventdata, handles)
% hObject    handle to Load_Single_Subject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file_name, file_path] = uigetfile('*','Select file');
handles.dat.data_file_name=file_name;
if(~file_name)
%     [~,~,ext]=fileparts(fullfile(file_path,file_name));
%     if(strcmp(ext,'.set'))
%         EEG = pop_loadset('filename',file_name,'filepath', file_path);
%         EEG = eeg_checkset( EEG );
%         handles.dat.EEG = EEG;
%     end
    msgbox('No file has been selected');
    return;
end
load_handles_toolbox(handles);

guidata(hObject,handles)


% --------------------------------------------------------------------
function Load_Group_Of_Subjects_Callback(hObject, eventdata, handles)
% hObject    handle to Load_Group_Of_Subjects (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
folder_path=uigetdir(handles.dat.toolbox_path,'Select folder with data');
if(folder_path)
    handles.dat.path_to_files=folder_path;
else
    msgbox('No folder has been selected');
    return;
end
load_handles_toolbox(handles);

guidata(hObject,handles);
    


% --------------------------------------------------------------------

function view_log_Callback(hObject, eventdata, handles)
    if isfield(handles.dat,'path_to_save')
        display_text_file(handles.data.path_to_save);
    else
        msgbox('Nothing has been loaded yet.','Warning')
    end
guidata(hObject,handles);


% --------------------------------------------------------------------
function Load_path_to_save_Callback(hObject, eventdata, handles)
% hObject    handle to Load_path_to_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    path=uigetdir(handles.dat.toolbox_path,'Select folder to save results');
    if(isdir(path))
        handles.dat.path_to_save=path;
    else
    msgbox('No folder was selected');
    return;
    end
    
    load_handles_toolbox(handles);
    guidata(hObject,handles)

    


% --- Executes on key press with focus on function_group_list_box and none of its controls.
function function_group_list_box_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to function_group_list_box (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Add_toolbox_path_Callback(hObject, eventdata, handles)
% hObject    handle to Add_toolbox_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
extra_toolbox_path=uigetdir(handles.dat.toolbox_path,'Select folder');
addpath(genpath(extra_toolbox_path));
