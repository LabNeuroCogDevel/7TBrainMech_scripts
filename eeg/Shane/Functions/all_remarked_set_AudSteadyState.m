function [setfiles] = all_remarked_set_AudSteadyState(varargin)
% ALL_REMARKED_SET - return cell array of paths to initial set files
% varargin options:
%  * 'only128', true or 'only64', true will give set files > or < 10^9 bytes
%  * 'struct',true return dir struct instead of cell of files

    % handle options
    p = inputParser;
    p.addOptional('only128',0, @(x) validateattributes(x,{'logical'},{'scalar'}))
    p.addOptional('only64', 0, @(x) validateattributes(x,{'logical'},{'scalar'}))
    p.addOptional('struct', 0, @(x) validateattributes(x,{'logical'},{'scalar'}))
    p.parse(varargin{:})
    
    % search for files
    setfiles = dir(hera('Projects/7TBrainMech/scripts/eeg/Shane/AudSteadyState/remarked/1*_20*.set'));
    % remove those that don't match a lunaid
    good_name = arrayfun(@(x) ~isempty(regexp(x.name,'\d{5}_\d{8}','once')), setfiles);
    setfiles = setfiles(good_name);
    
    subjs128 = [setfiles.bytes] > 10^9;
    % there is a better way add a struct element to each in array?
    for i=1:length(subjs128)
        setfiles(i).is128 = subjs128(i);
    end
    
    % 128 only??
    if p.Results.only128
        setfiles=setfiles(subjs128);
    % only 64
    elseif p.Results.only64
        setfiles=setfiles(~subjs128);
    end
    
    % if we just want struct, we're done
    if p.Results.struct
        return
    end
    
    % otherwise we need to collapse folder, name into one path
    setfiles = arrayfun(@(x) fullfile(x.folder, x.name),...
               setfiles(~[setfiles.isdir]), 'Uni',0); 

end