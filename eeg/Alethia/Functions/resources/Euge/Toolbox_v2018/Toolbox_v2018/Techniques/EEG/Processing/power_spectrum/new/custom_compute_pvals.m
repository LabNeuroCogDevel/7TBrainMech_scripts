function pvals = custom_compute_pvals(oridat, surrog, tail)
    
    if nargin < 3
        tail = 'both';
    end;
    
    if custom_myndims(oridat) > 1        
        if size(oridat,2) ~= size(surrog, 2) | myndims(surrog) == 2
            if size(oridat,1) == size(surrog, 1)
                surrog = repmat( reshape(surrog, [size(surrog,1) 1 size(surrog,2)]), [1 size(oridat,2) 1]);
            elseif size(oridat,2) == size(surrog, 1)
                surrog = repmat( reshape(surrog, [1 size(surrog,1) size(surrog,2)]), [size(oridat,1) 1 1]);
            else
                error('Permutation statistics array size error');
            end;
        end;
    end;

    surrog = sort(surrog, custom_myndims(surrog)); % sort last dimension
    
    if custom_myndims(surrog) == 1    
        surrog(end+1) = oridat;        
    elseif custom_myndims(surrog) == 2
        surrog(:,end+1) = oridat;        
    elseif custom_myndims(surrog) == 3
        surrog(:,:,end+1) = oridat;
    else
        surrog(:,:,:,end+1) = oridat;
    end;

    [tmp idx] = sort( surrog, custom_myndims(surrog) );
    [tmp mx]  = max( idx,[], custom_myndims(surrog));        
                
    len = size(surrog,  custom_myndims(surrog) );
    pvals = 1-(mx-0.5)/len;
    if strcmpi(tail, 'both')
        pvals = min(pvals, 1-pvals);
        pvals = 2*pvals;
    end;    
    