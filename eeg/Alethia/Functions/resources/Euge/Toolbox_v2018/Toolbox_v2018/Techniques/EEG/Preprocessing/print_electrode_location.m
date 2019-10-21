function print_electrode_location(file_name,EEG,data)

fileID = fopen([data.path file_name],'w');
%formatSpec = '%d %s %.1f %.1f %.1f\r\n';
formatSpec = '%s\r\n';
for ch = 1 : length(EEG.chanlocs)
    x = EEG.chanlocs(ch).X;
    y = EEG.chanlocs(ch).Y;
    z = EEG.chanlocs(ch).Z;   
    display([num2str(ch) ' ' EEG.chanlocs(ch).labels ' ' num2str(x) ' ' num2str(y) ' ' num2str(z)])
    str_to_print = [num2str(ch) ' ' EEG.chanlocs(ch).labels ' ' num2str(x) ' ' num2str(y) ' ' num2str(z)];
    fprintf(fileID,formatSpec,str_to_print);
end

fclose(fileID);