function EEG = load_electrode_location_into_EEG(node_file_name,EEG,data)

electrodes = load_electrodes_from_node([data.path node_file_name]);                                                                   

if length(electrodes.x) ~= length(EEG.chanlocs)
    error('Channel number of dataset and node file are not the same.')
end

for ch = 1 : length(EEG.chanlocs)
    EEG.chanlocs(ch).X = electrodes.x(ch);
    EEG.chanlocs(ch).Y = electrodes.y(ch);
    EEG.chanlocs(ch).Z = electrodes.z(ch);
end

end