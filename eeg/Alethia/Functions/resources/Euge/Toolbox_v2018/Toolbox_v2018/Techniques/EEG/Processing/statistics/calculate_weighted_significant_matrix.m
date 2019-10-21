function [weightedSignificantMatrixMask, weightedSignificantMatrix] = calculate_weighted_significant_matrix(alpha,significantMatrix,surroundingsWeight)

%matrix i,j
rowNr = size(significantMatrix,1);
columnNr = size(significantMatrix,2);
weightedSignificantMatrix = zeros(rowNr,columnNr);
weightedSignificantMatrixMask = zeros(rowNr,columnNr);

for i = 1 : rowNr
    for j = 1 : columnNr
        
        cellValue = significantMatrix(i,j);
        neibourhoodValues = [];
        
        if i ~= 1 && i~= rowNr && j ~= 1 && j ~= columnNr
            neighbour1 = significantMatrix(i-1,j-1);
            neighbour2 = significantMatrix(i-1,j);
            neighbour3 = significantMatrix(i-1,j+1);
            neighbour4 = significantMatrix(i,j+1);
            neighbour5 = significantMatrix(i+1,j+1);
            neighbour6 = significantMatrix(i+1,j);
            neighbour7 = significantMatrix(i+1,j-1);
            neighbour8 = significantMatrix(i,j-1);
            
            neibourhoodValues = [neighbour1 neighbour2 neighbour3 neighbour4 neighbour5 neighbour6 neighbour7 neighbour8];
        else
            if i == 1
                if j == 1
                    neighbour1 = significantMatrix(i,j+1);
                    neighbour2 = significantMatrix(i+1,j+1);
                    neighbour3 = significantMatrix(i+1,j);
                    neibourhoodValues = [neighbour1 neighbour2 neighbour3];
                else
                    if j == columnNr
                        neighbour1 = significantMatrix(i+1,j);
                        neighbour2 = significantMatrix(i+1,j-1);
                        neighbour3 = significantMatrix(i,j-1);
                        neibourhoodValues = [neighbour1 neighbour2 neighbour3];
                    else
                        neighbour1 = significantMatrix(i,j+1);
                        neighbour2 = significantMatrix(i+1,j+1);
                        neighbour3 = significantMatrix(i+1,j);
                        neighbour4 = significantMatrix(i+1,j-1);
                        neighbour5 = significantMatrix(i,j-1);
                        neibourhoodValues = [neighbour1 neighbour2 neighbour3 neighbour4 neighbour5];
                    end
                end
            else
                if i == rowNr
                    if j == 1
                    neighbour1 = significantMatrix(i-1,j);
                    neighbour2 = significantMatrix(i-1,j+1);
                    neighbour3 = significantMatrix(i,j+1);
                    neibourhoodValues = [neighbour1 neighbour2 neighbour3];
                    else
                        if j == columnNr
                            neighbour1 = significantMatrix(i-1,j-1);
                            neighbour2 = significantMatrix(i-1,j);
                            neighbour3 = significantMatrix(i,j-1);
                            neibourhoodValues = [neighbour1 neighbour2 neighbour3];
                        else
                            neighbour1 = significantMatrix(i-1,j-1);
                            neighbour2 = significantMatrix(i-1,j);
                            neighbour3 = significantMatrix(i-1,j+1);
                            neighbour4 = significantMatrix(i,j+1);
                            neighbour5 = significantMatrix(i,j-1);
                            neibourhoodValues = [neighbour1 neighbour2 neighbour3 neighbour4 neighbour5];
                        end
                    end
                else
                    if j == 1 
                        neighbour1 = significantMatrix(i-1,j);
                        neighbour2 = significantMatrix(i-1,j+1);
                        neighbour3 = significantMatrix(i,j+1);
                        neighbour4 = significantMatrix(i+1,j+1);
                        neighbour5 = significantMatrix(i+1,j);
                        neibourhoodValues = [neighbour1 neighbour2 neighbour3 neighbour4 neighbour5];
                    else
                        if j == columnNr 
                            neighbour1 = significantMatrix(i-1,j-1);
                            neighbour2 = significantMatrix(i-1,j);
                            neighbour3 = significantMatrix(i+1,j);
                            neighbour4 = significantMatrix(i+1,j-1);
                            neighbour5 = significantMatrix(i,j-1);
                            neibourhoodValues = [neighbour1 neighbour2 neighbour3 neighbour4 neighbour5];
                        else
                            display('ERROR- CASO NO CONTEMPLADO')
                        end
                    end
                end
            end
        end
        
        meanNeighbourhoodValues = mean(neibourhoodValues);  
        weightedSignificantValue = cellValue*(1-surroundingsWeight) + meanNeighbourhoodValues*surroundingsWeight;
        weightedSignificantMatrix(i,j) = weightedSignificantValue;
        
        maskValue = 0;
        
        if weightedSignificantValue <= alpha
            maskValue = 1;
        end
        weightedSignificantMatrixMask(i,j) = maskValue;
    end
end