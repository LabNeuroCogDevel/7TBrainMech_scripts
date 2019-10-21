%MY POP NEWTIMEF
% pop_newtimef() - Returns estimates and plots of event-related (log) spectral
%           perturbation (ERSP) and inter-trial coherence (ITC) phenomena 
%           timelocked to a set of single-channel input epochs 
%
% Usage:
%   >> pop_newtimef(EEG, typeplot);          % pop_up window
%   >> pop_newtimef(EEG, typeplot, lastcom); % pop_up window
%   >> pop_newtimef(EEG, typeplot, channel); % do not pop-up window
%   >> pop_newtimef(EEG, typeproc, num, tlimits,cycles,
%                        'key1',value1,'key2',value2, ... );   
%     
% Graphical interface:
%   "Channel/component number" - [edit box] this is the index of the data 
%              channel or the index of the component for which to plot the
%              time-frequency decomposition.
%   "Sub-epoch time limits" - [edit box] sub epochs may be extracted (note that
%              this function aims at plotting data epochs not continuous data).
%              You may select the new epoch limits in this edit box.
%   "Use n time points" - [muliple choice list] this is the number of time
%              points to use for the time-frequency decomposition. The more
%              time points, the longer the time-frequency decomposition
%              takes to compute.
%   "Frequency limits" - [edit box] these are the lower and upper
%              frequency limit of the time-frequency decomposition. Instead
%              of limits, you may also enter a sequence of frequencies. For
%              example to compute the time-frequency decomposition at all
%              frequency between 5 and 50 hertz with 1 Hz increment, enter "1:50"
%   "Use limits, padding n" - [muliple choice list] "using limits" means
%              to use the upper and lower limits in "Frequency limits" with
%              a specific padding ratio (padratio argument of newtimef).
%              The last option "use actual frequencies" forces newtimef to
%              ignore the padratio argument and use the vector of frequencies  
%              given as input in the "Frequency limits" edit box.
%   "Log spaced" - [checkbox] you may check this box to compute log-spaced
%              frequencies. Note that this is only relevant if you specify
%              frequency limits (in case you specify actual frequencies,
%              this parameter is ignored).
%   "Use divisive baseline" - [muliple choice list] there are two types of
%              baseline correction, additive (the baseline is subtracted)
%              or divisive (the data is divided by the baseline values).
%              The choice is yours. There is also the option to perform 
%              baseline correction in single trials. See the 'trialbase' "full"
%              option in the newtimef.m documentation for more information.
%   "No baseline" - [checkbox] check this box to compute the raw time-frequency
%              decomposition with no baseline removal.
%   "Wavelet cycles" - [edit box] specify the number of cycle at the lowest 
%              and highest frequency. Instead of specifying the number of cycle 
%              at the highest frequency, you may also specify a wavelet
%              "factor" (see newtimef help message). In addition, it is
%              possible to specify actual wavelet cycles for each frequency
%              by entering a sequence of numbers.
%   "Use FFT" - [checkbox] check this checkbox to use FFT instead of
%              wavelet decomposition.
%   "ERSP color limits" - [edit box] set the upper and lower limit for the
%              ERSP image. 
%   "see log power" - [checkbox] the log power values (in dB) are plotted. 
%              Uncheck this box to plot the absolute power values.
%   "ITC color limits" - [edit box] set the upper and lower limit for the
%              ITC image. 
%   "plot ITC phase" - [checkbox] check this box plot plot (overlayed on
%              the ITC amplitude) the polarity of the ITC complex value.
%   "Bootstrap significance level" - [edit box] use this edit box to enter
%              the p-value threshold for masking both the ERSP and the ITC
%              image for significance (masked values appear as light green)
%   "FDR correct" - [checkbox] this correct the p-value for multiple comparisons
%              (accross all time and frequencies) using the False Discovery
%              Rate method. See the fdr.m function for more details.
%   "Optional newtimef arguments" - [edit box] addition argument for the
%              newtimef function may be entered here in the 'key', value
%              format.
%   "Plot Event Related Spectral Power" - [checkbox] plot the ERSP image
%              showing event related spectral stimulus induced changes
%   "Plot Inter Trial Coherence" - [checkbox] plot the ITC image.
%   "Plot Curve at each frequency" - [checkbox] instead of plotting images,
%              it is also possible to display curves at each frequency.
%              This functionality is beta and might not work in all cases.
% 
% Inputs:            
%   INEEG    - input EEG dataset
%   typeproc - type of processing: 1 process the raw channel data 
%                                  0 process the ICA component data
%   num      - component or channel number
%   tlimits  - [mintime maxtime] (ms) sub-epoch time limits to plot
%   cycles   -  > 0 --> Number of cycles in each analysis wavelet 
%               = 0 --> Use FFTs (with constant window length 
%                       at all frequencies)
%
% Optional inputs:
%    See the newtimef() function.
%    
% Outputs: Same as newtimef(); no outputs are returned when a
%          window pops-up to ask for additional arguments
%
% Saving the ERSP and ITC output values:
%    Simply look up the history using the eegh function (type eegh).
%    Then copy and paste the pop_newtimef() command and add output args.
%    See the newtimef() function for a list of outputs. For instance,
% >> [ersp itc powbase times frequencies] = pop_newtimef( EEG, ....);
%
% Author: Arnaud Delorme, CNL / Salk Institute, 2001 
%
% See also: newtimef(), eeglab() 

% Copyright (C) 2002 University of California San Diego
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% 01-25-02 reformated help & license -ad 
% 03-08-02 add eeglab option & optimize variable sizes -ad
% 03-10-02 change newtimef call -ad
% 03-18-02 added title -ad & sm
% 04-04-02 added outputs -ad & sm

function [P,R,mbase,timesout,freqs,Pboot,Rboot,alltfX,PA,ERP,maskersp, maskitc, g,Pboottrials] = my_pop_new_timef_2(EEG, typeproc, num, tlimits, cycles,freqRange,alpha,fdrCorrect,scale,baseline,basenorm,erpsmax,marktimes, varargin );
varargout{1} = '';
lastcom = num;


% compute epoch limits
% --------------------
if isempty(tlimits)
	tlimits = [EEG.xmin, EEG.xmax]*1000;
end;	
pointrange1 = round(max((tlimits(1)/1000-EEG.xmin)*EEG.srate, 1));
pointrange2 = round(min((tlimits(2)/1000-EEG.xmin)*EEG.srate, EEG.pnts));
pointrange = [pointrange1:pointrange2];

% call function sample either on raw data or ICA data
% ---------------------------------------------------
tmpsig = EEG.data(num,pointrange,:);
tmpsig = reshape( tmpsig, length(num), size(tmpsig,2)*size(tmpsig,3));
size(tmpsig)



% plot the datas and generate output command
% --------------------------------------------
%[P,R,mbase,timesout,freqs,Pboot,Rboot,alltfX,PA] = newtimef( tmpsig(:, :), length(pointrange), [tlimits(1) tlimits(2)], EEG.srate, cycles , 'baseline',[0], 'freqs', [1 70], 'plotitc' , 'off', 'plotphase', 'off', 'padratio', 1);

basenormvalue = 'off';
if basenorm == 1
    basenormvalue = 'on';
end

if isempty(baseline)
    baseline = [0];
end

fdrCorrect = 'none';
if fdrCorrect == 1
    fdrCorrect = 'fdr';
end


%alpha
%fdrCorrect
%baseline
%marktimes
%erpsMax

if alpha ~= 0
    [P,R,mbase,timesout,freqs,Pboot,Rboot,alltfX,PA,ERP,maskersp, maskitc, g,Pboottrials] = my_new_timef( tmpsig(:, :), length(pointrange), [tlimits(1) tlimits(2)], EEG.srate, cycles , 'baseline',baseline, 'freqs', [freqRange], 'plotitc' , 'off', 'plotphase', 'off', 'padratio', 4, 'basenorm', basenormvalue,'alpha', alpha,'mcorrect','fdr','erspmax',erpsmax,'marktimes',marktimes);
else
    [P,R,mbase,timesout,freqs,Pboot,Rboot,alltfX,PA,ERP,maskersp, maskitc, g,Pboottrials] = my_new_timef( tmpsig(:, :), length(pointrange), [tlimits(1) tlimits(2)], EEG.srate, cycles , 'baseline',baseline, 'freqs', [freqRange], 'plotitc' , 'off', 'plotphase', 'off', 'padratio', 4, 'basenorm', basenormvalue,'mcorrect','fdr','erspmax',erpsmax,'marktimes',marktimes);
end

% if alpha ~= 0
%     baseCmd = [baseCmd '"alpha",' num2str(alpha)];
% end
% 
% if fdrCorrect == 1
%     baseCmd = [baseCmd '"mcorrect","fdr"'];
% end
% baseCmd = [baseCmd ');']
% [P,R,mbase,timesout,freqs,Pboot,Rboot,alltfX,PA,ERP,maskersp, maskitc, g,Pboottrials] = eval(baseCmd);