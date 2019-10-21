function [SMI_out, wSMI_out,R_SMI_out, R_wSMI_out] = MI_SMI_and_wSMI(signal,sym_prob,kernel)

% ---------------------------------------------------------------------
% Data should be on the symbolic space
% - signal should be a matrix of (channels x samples)
% - sym_prob is the probability of the symbols in each channel 
%  should be a matrix in the form of (channels x number of symbols)
% ---------------------------------------------------------------------
% (c) Jacobo Sitt
% ---------------------------------------------------------------------

channels = size(signal,1);
samples  = size(signal,2);

n_symbols = factorial(kernel);

wSMI_out   = zeros(channels*(channels-1)/2,1);
SMI_out    = zeros(channels*(channels-1)/2,1);
R_wSMI_out = zeros(channels*(channels-1)/2,1);
R_SMI_out  = zeros(channels*(channels-1)/2,1);

joint_prob = zeros(n_symbols^2,channels*(channels-1)/2);

forb = [5 6 4 3 1 2];

%%% PE calculation
PE            = sym_prob.*log(sym_prob);
PE(isnan(PE)) = 0;
PE            = -sum(PE,2);

index = 0;
for ch1 = 1:(channels-1) %%% from channel 
    
    for ch2 = (ch1+1):channels %%% to channel 
 
        index = index+1;
        
        meta_signal = signal(ch1,:) + (signal(ch2,:)-1)*n_symbols; %% create a meta_signal using both signals
        
                
        for xxx = 1:n_symbols^2
            joint_prob(xxx,index) = sum(meta_signal == xxx)/samples;
        end
        
        
        out(index) = 0;
        
        for symbols_ch1 = 1:n_symbols
            for symbols_ch2 = 1:n_symbols
                
                if symbols_ch1 == symbols_ch2 || forb(symbols_ch1) == symbols_ch2
                    w = 0;
                else
                    w = 1;
                end
                
                
                if joint_prob(symbols_ch1+(symbols_ch2-1)*n_symbols,index) > 0 %&& sym_prob(ch1,symbols_ch1) > 0 && sym_prob(ch2,symbols_ch2) > 0 %% avoid log(0) and divide by zero
                    
                    if sym_prob(ch1,symbols_ch1) == 0 || sym_prob(ch2,symbols_ch2) == 0
                        error('error: joint prob>0 but single prob == 0')
                    end
                
                    aux = joint_prob(symbols_ch1+(symbols_ch2-1)*n_symbols,index)*log(joint_prob(symbols_ch1+(symbols_ch2-1)*n_symbols,index)/sym_prob(ch1,symbols_ch1)/sym_prob(ch2,symbols_ch2));
                    wSMI_out(index) = wSMI_out(index) + w*aux;
                    SMI_out(index)  =  SMI_out(index) +   aux;
                    
                
                end
                
                    R_wSMI_out(index) = wSMI_out(index)/(PE(ch1)+PE(ch2));
                    R_SMI_out(index)  =  SMI_out(index)/(PE(ch1)+PE(ch2));
 
                
            end
        end
        
    end
    
end

wSMI_out = wSMI_out / log(n_symbols);
SMI_out = SMI_out / log(n_symbols);
