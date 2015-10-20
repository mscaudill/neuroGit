function [normedCntrlCurrents, normedLedCurrents] = ...
                           csNormed_peakCurrent(meanSignals, stimTiming,...
                                                samplingFreq)
%csNormed_peakCurrent takes computes the peak current for cs data collected
%in voltage-clamp mode for a single angle
% INPUTS:               meanSignals: a cell array of signals meanSignals{1}
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
%%%%%%%%% OBTAIN INTERVAL OF DATA TO COMPUTE MAX CURRENT OVER %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We need the indices in meanSignals of when the stimulus started and
% ended to compute the maximum
% Stim starts after delay period (i.e. stimTiming(1))
stimStartIdx = samplingFreq*stimTiming(1);
% Stimulus ends after delay + duration period (stimTiming(2))
stimEndIdx = samplingFreq*(stimTiming(1)+stimTiming(2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% COMPUTE MAXIMUM CURRENTS FOR EACH CONDITION %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for each cell (cntrl trials, ledTrials) concatenate all the surround
% conditions along the 2nd (col) dim
cntrlTrialsMat = cat(2,meanSignals{1}{:});

% only take idxs (i.e. rows) that fall between stimStartIdx and stimEndIdx
cntrlTrialsMat = cntrlTrialsMat(stimStartIdx:stimEndIdx,:);

% now get the maximum currents during the stimulus
maxCntrlCurrents = max(cntrlTrialsMat,[],1);

% now compute the normedMaxCurrents relative to the center alone condition
normedCntrlCurrents = maxCntrlCurrents/maxCntrlCurrnets(1);

% Repeat the same for ledTrials if they are present
if ~isempty(meanSignals{2})
    % concatenate along col dim
    ledTrialsMat = cat(2,meanSignals{2}{:});
    
    % only take stim Idxs
    ledTrialsMat = ledTrialsMat(stimStartIdx:stimEndIdx,:);
    
    % get the max currents
    maxLedCurrents = max(ledTrialsMat,[],1);
    
    % and comput the normed led currents
    normedLedCurrents = maxLedCurrents/maxLedCurrents(1);
    
else
    normedLedCurrents = [];

end


end

