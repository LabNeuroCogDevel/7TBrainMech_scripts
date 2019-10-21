function [ output_args ] = get_first_coincidence( list , str)
%GET_FIRST_COINCIDENCE Returns the value of the first element that matchs
%the string.
    output_args = 0;
    for i = 1:length(list(:,1))
        if strcmp(list(i,:), str)
            output_args = i;
            break;
        end
    end
    
end

