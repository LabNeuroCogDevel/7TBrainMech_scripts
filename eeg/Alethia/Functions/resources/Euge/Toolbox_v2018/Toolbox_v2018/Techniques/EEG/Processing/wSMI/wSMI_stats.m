function [tsignificantMat,t,p] = wSMI_stats(path,condition1,condition2,tau,channelNr,stat_method,alpha)
%returns channelNr*channelNr statistical matrix with t values for selected
%method and be optionally be printed as .edge

%matrix C1 and C2 must have same size
[C1] = load_wSMI_connectivity_matrix(path,condition1,tau,channelNr);

[C2] = load_wSMI_connectivity_matrix(path,condition2,tau,channelNr);

[tsignificantMat,t,p] = connectivity_stats(C1,C2,stat_method,alpha);
