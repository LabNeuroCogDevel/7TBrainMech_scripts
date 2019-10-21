function write_edge_file(fileName,connectionMatrix)

edgeFileName = [fileName '.edge'];
dlmwrite(edgeFileName,connectionMatrix,'delimiter','\t');