function [full_answer] = dynamic_inputdlg( params, title, lines, defaults )
%SAVE_FILE Summary of this function goes here
%   Detailed explanation goes here
params_per_page = 10;
from = 1;
to = min(length(params), params_per_page);
full_answer = {};
while from <= to
    if ~isempty(params(from:to))
        answer = inputdlg(params(from:to),title, lines, defaults(from:to));
        if ~isempty(answer)
            full_answer(from:to) = answer(:);
        else
            full_answer = {};
            return
        end
    end
    from = to + 1;
    to = min(length(params),params_per_page + from);
end