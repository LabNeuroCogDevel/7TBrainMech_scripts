function write_node_file(electrodes,connectionMatrix,fileName2Save,nodeSpecStruct,mode)
% electrodes is a struct with the following information
%   * label of channel
%   * x
%   * y
%   * z
%connectionMatrix: channelNr*channelNr matrix
%nodeSpecStruct: contains the info relative to size, color, etc... relative
%to the mode selected
%mode:  connectionNr -> size of node is proportional to connectionNr
%       condition -> size of node depends on condition, color of default
%       value is determined
connMat = connectionMatrix;
connMat(connectionMatrix~=0) = 1;
connections = sum(connMat)';

color = create_color_values_of_neuro_anatomic_regions(electrodes.labels);

fileID = fopen([fileName2Save '.node'],'w');
formatSpec = '%s\r\n';

for i = 1 : size(connectionMatrix,1)
    color2print= '';
    size2print = '';

    switch(mode)
        case 'connectionNr' 
            color2print = num2str(color(i));
            size2print = num2str(connections(i));
        case 'condition'
            defaultIndex = 0;
            otherIndex = 0;
            if connections(i) == 0
                defaultIndex = struct_find(nodeSpecStruct,'condition','default');
                color2print = nodeSpecStruct(defaultIndex).color;
                size2print = nodeSpecStruct(defaultIndex).size;
            else
                color2print = num2str(color(i));
                otherIndex = struct_find(nodeSpecStruct,'condition','other');
                size2print = nodeSpecStruct(otherIndex).size;
            end            
        otherwise
            color2print = -1;
            size2print = -1;
    end

    text2Print = [num2str(electrodes.x(i)) ' ' num2str(electrodes.y(i)) ' ' num2str(electrodes.z(i)) ' ' color2print ' ' size2print ' ' electrodes.labels{i} ];
    fprintf(fileID,formatSpec,text2Print);

end

fclose(fileID);
