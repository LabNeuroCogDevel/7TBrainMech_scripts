function [TT,AA] = t2fitLin(M,time,threshold)
% function [TT,AA] = t2fitLin(M,t,threshold)
% TT : output t1 map matrix (row x col)
% AA : initial signal intensity map
% M : input matrix size of row x col x (length(t))
% time : sampling time vector
% threshold : threshold intensity level
%%% T0=clock;[TT,AA]=t2fitLin(single(T2sMapData3D),1e-3*[6.24 12 18 24 30]',150); save T2sMap3D.mat TT AA; T1=clock;eT1T0=etime(T1,T0);save eT1T0.mat eT1T0
%%% T0=clock;[TT,AA]=t2fitLin(single(T2sMapData3D),1e-3*[8.7 13.98 20 26 32 40 48]',400.0); save T2sMap3D.mat TT AA; T1=clock;eT1T0=etime(T1,T0);save eT1T0.mat eT1T0

sz=size(M);
row = sz(1);
col = sz(2);
sli = sz(3);

TT = zeros( sz(1:length(sz)-1) );
AA = zeros( sz(1:length(sz)-1) );

lnThreshold = log(threshold);
%lnM = log(M);

if(length(sz) == 3)
    for m=1:row
        for n=1:col
%            data = squeeze(lnM(m,n,:));
            data = log(squeeze(M(m,n,:)));
            if( data(1) < lnThreshold )
                TT(m,n) = 0.0;
                AA(m,n) = 0.0;
            else
                %%% ln(S) = -R2*TE + ln(a1)
                P = polyfit(time,data,1);
                TT(m,n) = P(1);
                AA(m,n) = P(2);
            end
        end
    end
elseif(length(sz) == 4)
    for k=1:sli
        for m=1:row
            for n=1:col
%                data = squeeze(lnM(m,n,k,:));
                data = log(squeeze(M(m,n,k,:)));
                
                %% Threshold level will be applied for the first echo
                if( data(1) < lnThreshold )
                    TT(m,n,k) = 0.0;
                    AA(m,n,k) = 0.0;
                else
                    %%% ln(S) = -R2*TE + ln(a1)
                    P = polyfit(time,data,1);
                    TT(m,n,k) = P(1);
                    AA(m,n,k) = P(2);
                end
            end
        end
        k
    end
else
    error('Dimension of input data should be 3 or 4.');
end

TT = -1./TT;
AA = exp(AA);
TT( find(TT < 0.0 | TT > 4.0) ) = 0;
AA( find(TT < 0.0 | TT > 4.0) ) = 0;
AA( find(AA < 0.0) ) = 0;
TT( find(AA < 0.0) ) = 0;
