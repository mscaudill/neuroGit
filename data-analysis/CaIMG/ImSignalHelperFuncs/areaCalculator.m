function [meanAreas, stdAreas, roiKeys, areaMat] = areaCalculator(signalMaps,...
                                                        roiSetNum,...
                                                        roiNum,stimulus,...
                                                        fileInfo)
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
% areaCalculator(signalMaps, RoiSetNumber, roiNum) approximates the areas
% below the curve of a single signalMap specified by the roiSet# and roi#
% and signalMaps cell array stored within an imExp. It uses the trapezoidal
% rule to approximate the area
%
% INPUTS:                           signalMaps: a cell array of cells
%                                               containing signal maps 
%                                               corresponding to each roi 
%                                               in the imExp. Signal Maps
%                                               are the df/f signals across
%                                               stimulus conditions
%                                   RoiSetNum:  index corresponding to the
%                                               cell containing signal maps
%                                               for that trial
%                                   roiNum:    index used to identify a
%                                              particular signal map within
%                                              the set of signal maps for
%                                              that trial
%                                   stimulus:  stimulus struct containing
%                                              all stimuli info in imExp
%                                   fileInfo: structure containg all file
%                                             information in the imExp
%
% OUTPUTS:                          meanAreas: mean area below the signals
%                                              in the signals map
%                                   stdAreas:  standard deviation of the
%                                              areas below the signals in 
%                                              the signal maps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% OBTAIN ALL THE SIGNALS AND CHECK MAP DIMENSIONS %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will first obtain all the signals from the signal maps and check the
% number of parameters that were varied since this will affect our mean
% calculation ( see commented exs)
% EXS:
% if the dim of the map is 1 (say an orientation exp) the signals map looks
% like {{1xnumTrials}...{}} where the cell array contains 1xnumAngles of
% cells with 1xnumTrials
%
% if the dim of the map is 2 (say a scs map) the signal map looks like
% {{numTrialsxnumConds}....{}} where the outer cell contains cells 
% corresponding to individual center angles

% Get the mapObj for this roi specified byt the roiSetNum and
% roiNum
roiMapObj = signalMaps{roiSetNum}{roiNum};

% get all the signals (map values) from the roiMapObj
roiSignals = roiMapObj.values;

% we will also pass the keys of the map back to the user 
roiKeys = roiMapObj.keys;

% Check the number of parameters for the roiMap
mapParams = min(size(roiSignals{1}));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base','roiSignals',roiSignals)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% CALCULATE THE START AND END FRAMES OF THE INTEGRATION %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will integrate the signals only during the stimulus time window so we
% need to calculate the start and end frames of the stimulus window
startFrame = round(stimulus(1,1).Timing(1)*fileInfo(1,1).imageFrameRate);
endFrame = round((stimulus(1,1).Timing(1) + ...
                  stimulus(1,1).Timing(2))*fileInfo(1,1).imageFrameRate);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% CALCULATE AREAS BELOW EACH SIGNAL %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will no loop through the outer index of allSignals (in orientation and
% scs exps this index is the angles). Each will return a cell that is
% 1*numtrials (for 1D maps) or numTrials*numConds (for 2D maps). We will
% compute the areas under each using cellfun then convert to a matrix and
% get the mean and standard deviations. more explanation to follow

for angle = 1:numel(roiSignals)
    % for each angle, we have a cell array of 1*numtrials OR
    % numTrials*numConds. We will use cellfun to compute the areas under
    % each trial/cond
    areas = cellfun(@(x) trapz(x(startFrame:endFrame)),...
                    roiSignals{angle}, 'UniformOut',0);
           
    % we will now convert the areas of the trials, conds to a matrix
    areaMat = cell2mat(areas);
    
    % compute the mean area across trials
    if mapParams == 1;
        % we first rotate the areas matrix to be 1*numTrials (Matlab
        % auto-rotates this before to keep the long dim along rows so we
        % undo that here.
        areaMat = areaMat';
        % if we have 1 parameter, then the mean areas will be a scalar
        % value for each angle (we meaned over the trials)
        meanAreas{angle} = mean(areaMat,2);
        stdAreas{angle} = std(areaMat,0,2);
        
    elseif mapParams > 1
        % If we have more than 1 parameter we take the mean across the
        % first dim (i.e. the number of trials). This will give a cell over
        % angles containing the conditions as columns ex: {[1x5]...[1x5]}
        % where the outer cell is over angles and the arrays contain the
        % trial meaned scalar area for each of five conditions
        meanAreas{angle} = mean(areaMat,1);
        stdAreas{angle} = std(areaMat,0,1);
    end
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%assignin('base', 'areas', areas)
assignin('base','meanAreas', meanAreas)
assignin('base','stdAreas', stdAreas)
end

