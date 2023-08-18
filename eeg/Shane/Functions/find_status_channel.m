function status_idx = find_status_channel(names)
   status_idx = find(cellfun(@(x) ~isempty(regexpi(x,'Status')), names));
   % 73 when w/ft_read_data
end