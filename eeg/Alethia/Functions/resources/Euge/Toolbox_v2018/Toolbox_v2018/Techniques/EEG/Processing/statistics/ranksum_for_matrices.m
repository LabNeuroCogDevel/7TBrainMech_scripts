function [p h zval ranksums] = ranksum_for_matrices(mat1,mat2,pvalue)

rows = size(mat1,1);
p = zeros(rows,1);
h = zeros(rows,1);
zval = zeros(rows,1);
ranksums = zeros(rows,1);

for row = 1 : rows
    mat1temp = mat1(row,:);
    mat2temp = mat2(row,:);
    [pval,hval,statsval] = ranksum(mat1temp,mat2temp,'alpha',pvalue);
    p(row) = pval;
    h(row) = hval;
    zval(row,1) = statsval.zval;
    ranksums(row) = statsval.ranksum;
end

    