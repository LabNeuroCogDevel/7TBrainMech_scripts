function [tsignificantMat,t,p] = connectivity_stats(C1,C2,stat_method,alpha)
%Performs statistical comparisons between C1 and C2, using the specified
%statistical method. 
%INPUTS:
%C1: connectivity matrix C1
%C2: connectivity matrix C2
%stat_method: string that specifies statistical method to be used. Possible
%values:
%           *ttest: performs a t-test using Matlab ttest2 function
%           *boot: bootstrap method using eeglab's statcond function with
%                  1000 permutations
%           *perm: permutation method using eeglab's statcond function with
%                   1000 permutations
%alpha: significant level considered, for a 5% percent alpha = 0.05
%OUTPUTS:
%tsignificantMat: matrix of statistical t values below the threshold
%established by the parameter's alpha value.
%t: complete statistical t value matrix - outcome from the statistical
%   comparison
%p: complete statistical p value matrix - outcome from the statistical
%   comparison
p=[]; %modificación 1/4/18
t=[];
h=[];
ci=[];
stats=[];
data1=[];
data2=[];
significantMat = zeros(size(C1,1),size(C1,1));
switch stat_method    
    case 'ttest'
        %TTEST
        data1 = reshape(C1,[size(C1,1)*size(C1,2),size(C1,3)]);
        data2 = reshape(C2,[size(C2,1)*size(C2,2),size(C2,3)]);
        [h,p,ci,stats] = ttest2(data1',data2');
        t = reshape(stats.tstat,[size(C1,1),size(C1,2)]);
        p = reshape(p,[size(C1,1),size(C1,2)]);
    case 'boot'
        %BOOTSTRAP
        [t, df, p] = statcond( {C1,C2}, 'method','bootstrap','naccu',1000);
    case 'perm'
        %PERMUTATIONS
        [t, df, p] = statcond( {C1,C2}, 'method','perm','naccu',1000);
 end

significantMat(p<=alpha) = 1;
tsignificantMat = t .* significantMat;
tsignificantMat(logical(eye(size(tsignificantMat)))) = 0;