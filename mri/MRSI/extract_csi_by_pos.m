function [val] = extract_csi_by_pos(csi,type, row, col)
%extract_csi extract csi from spreadsheet
%   csi can be read table or path to table
%   type is like 'GABA'
%   works on single row col
    if(ischar(csi)), csi=readtable(csi); end

    vals = csi.(type);
    idx=csi.Row == row & csi.Col==col;
    val = vals( idx );
end

