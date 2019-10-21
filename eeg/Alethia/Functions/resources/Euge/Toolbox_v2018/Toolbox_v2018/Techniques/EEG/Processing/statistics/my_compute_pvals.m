function pvals = my_compute_pvals(oridat, surrog, tail)
    
    if nargin < 3
        tail = 'both';
    end;
    
    if my_ndims(oridat) > 1        
        if size(oridat,2) ~= size(surrog, 2) | my_ndims(surrog) == 2
            if size(oridat,1) == size(surrog, 1)
                surrog = repmat( reshape(surrog, [size(surrog,1) 1 size(surrog,2)]), [1 size(oridat,2) 1]);
            elseif size(oridat,2) == size(surrog, 1)
                surrog = repmat( reshape(surrog, [1 size(surrog,1) size(surrog,2)]), [size(oridat,1) 1 1]);
            else
                error('Permutation statistics array size error');
            end;
        end;
    end;

    surrog = sort(surrog, my_ndims(surrog)); % sort last dimension
    
    if my_ndims(surrog) == 1    
        surrog(end+1) = oridat;        
    elseif my_ndims(surrog) == 2
        surrog(:,end+1) = oridat;        
    elseif my_ndims(surrog) == 3
        surrog(:,:,end+1) = oridat;
    else
        surrog(:,:,:,end+1) = oridat;
    end;

    [~, idx] = sort( surrog, my_ndims(surrog) );
    [~, mx]  = max( idx,[], my_ndims(surrog));        
                
    len = size(surrog,  my_ndims(surrog) );
    pvals = 1-(mx-0.5)/len;
    if strcmpi(tail, 'both')
        pvals = min(pvals, 1-pvals);
        pvals = 2*pvals;
    end;    
    



