function electrodes = load_electrodes_from_node(node_file_name)
%creates electrode struct loading values from input

%INPUT: 
%node_file_name: node file from which to construct the electrodes structure
%   column 1: x
%   column 2: y
%   column 3: z
%   column 4: size
%   column 5: color
%   column 6: label

%OUTPUT:
%electrode struct with the following fields
%   x
%   y
%   z
%   label

%load node file
fid = fopen(node_file_name,'r');
nodes = textscan(fid, '%f %f %f %d %d %s');
fclose(fid);

electrodes.x = nodes{1,1};
electrodes.y = nodes{1,2};
electrodes.z = nodes{1,3};
electrodes.labels = nodes{1,6};
