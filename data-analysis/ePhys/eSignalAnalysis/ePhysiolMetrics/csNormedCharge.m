function [normedCharges] = csNormedCharge(meanSignals,stimTiming,...
                                            samplingFreq)
%csNormedCharge computes the normalizedCharge relative to the center alone
%condition during visual stimulation,
% INPUTS:                meansignals: a cell array of signals meanSignals{1}
%                                   contains the cntrl data ordered by surr
%                                   cond and MeanSignals{2} contains
%                                   led data (if present) ordered by Surr 
%                                   cond
%                       stimTiming: 3 el-array of stimulus timing
%                       samplingFreq: sampling freq of meanSignals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%copyright (c) 2012  Matthew Caudill
%
%this program is free software: you can redistribute it and/or modify
%it under the terms of the gnu general public license as published by
%the free software foundation, either version 3 of the license, or
%at your option) any later version.
%
%this program is distributed in the hope that it will be useful,
%but without any warranty; without even the implied warranty of
%merchantability or fitness for a particular purpose.  see the
%gnu general public license for more details.
%
%you should have received a copy of the gnu general public license
%along with this program.  if not, see <http://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% OBTAIN INTERVAL OF DATA TO COMPUTE CHARGE OVER %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We need the indices in meanSignals of when the stimulus started and
% ended to compute the charge
% Stim starts after delay period (i.e. stimTiming(1))
stimStartIdx = round(samplingFreq*stimTiming(1));
% Stimulus ends after delay + duration period (stimTiming(2))
stimEndIdx = round(samplingFreq*(stimTiming(1)+stimTiming(2)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% COMPUTE THE AREA UNDER THE CURVE (CHARGE) %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for map=1:numel(meanSignals)
    if ~isempty(meanSignals{map})
        normedCharges{map} = ...
            cellfun(@(x) trapz(x(stimStartIdx:stimEndIdx)/samplingFreq),...
                                meanSignals{map});
    else
        normedCharges{map} = [];
end


end

