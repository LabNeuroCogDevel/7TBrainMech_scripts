function [ str, pos ] = get_current_popup_string( hObject )
%# getCurrentPopupString returns the currently selected string in the popupmenu with handle hh
contents = cellstr(get(hObject,'String'));
pos = get(hObject,'Value');
str = contents{get(hObject,'Value')};
