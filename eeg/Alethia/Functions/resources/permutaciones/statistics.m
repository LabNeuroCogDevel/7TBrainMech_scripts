function [tt df pvals] = statistics(cond,parametro)
% parametro puede ser 'on' para muestras pareadas o 'off' oara comparar
% entre grupos
if size(cond,2)==3

    %DATA={cond(1).data,cond(2).data,cond(3).data}; %esta es la linea
    %original, que permutea mal ya que mezcla sujetos-canales
    DATA={cond(1).mean,cond(2).mean,cond(3).mean};
    [tt df pvals] = statcond(DATA,'mode','bootstrap','paired',parametro,'naccu', 5000);
    
else if size(cond,2)==2
        
        
    %DATA={cond(1).data,cond(2).data}; %esta es la linea
    %original, que permutea mal ya que mezcla sujetos-canales
    DATA={cond(1).mean,cond(2).mean};
    [tt df pvals] = statcond(DATA,'mode','bootstrap','paired',parametro,'naccu', 5000);
   
    end
end

