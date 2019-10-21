function [signal_pe, nb, symbols] = pe_paralel(signal,kernel,tau)
% results = pe(signal,kernel)
% ---------------------------------------------------------------------

% make sure first dimension is used
if length(size(signal)) == 1 && size(signal,1) == 1, signal = signal'; end
% identify symbols
symbols = perms(1:kernel);

index = zeros(size(signal,1)-tau*(kernel-1),kernel);

aux=[]; %modificación 29/3/18
for k = (size(signal,1)-tau*(kernel-1)):-1:1
   
%     exec = '[unused index(k,:)] = sort([signal(k) signal(k+tau) signal(k+2*tau) ';
%     for i = 4:kernel %% only for kernel == 4
%         exec  = strcat(exec , [' signal(k+' num2str(i-1) '*tau) ']);
%     end
%     exec = strcat(exec , '],2,  ''descend'');');
%     eval(exec)
%     
   [unused aux(:,:,k)] = sort([signal(k,:) ;signal(k+tau,:); signal(k+2*tau,:)],1,  'descend');
  
end

aux2 = squeeze(aux(1,:,:))*9+squeeze(aux(2,:,:))*3+squeeze(aux(3,:,:));

n = 0;
simbs = [5 6 4 3 2 1];
signal_pe = zeros(size(aux2));
for s = [18    20    24    28    32    34]
    n =n +1;
    ii = find(aux2==s); % find symbol in data
    %nb(n) = length(ii); % count symbols
    signal_pe(ii) = simbs(n); % create signal in pe space
end

for i = 1:size(signal_pe,1)
    for s = 1:6
        nb(i,s) = length(find(signal_pe(i,:)==s));
    end
end
%nb = hist(signal_pe',6)';

end
