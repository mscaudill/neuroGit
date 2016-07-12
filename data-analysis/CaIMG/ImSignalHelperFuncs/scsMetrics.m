function [surroundOriIndex, surroundGains, suppressionIndex ] =...
                        scsMetrics(signalMaps, cellTypeOfInterest,...
                                   roiSetNum, roiNum, angle,...
                                   stimulus, fileInfo,framesDropped)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%copyright (c) 2013  Matthew Caudill
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
% scsMetrics computes several metrics to characterize a given cells
% surround orientation modulation. It returens the surround orientation
% index, surround gains and suppression index (see code for details about
% these metrics
% INPUTS:                          signalMaps:  a cell array of cells
%                                               containing signal maps 
%                                               corresponding to each roi 
%                                               in the imExp. Signal Maps
%                                               are the df/f signals across
%                                               stimulus conditions
%                                   cellTypeOfInterst:cellType of interest,
%                                               currently on pyr and som 
%                                               accepted
%                                   RoiSetNum:  index corresponding to the
%                                               cell containing signal maps
%                                               for that trial
%                                   roiNum:     index used to identify a
%                                               particular signal map in
%                                               the set of signal maps for
%                                               that trial 
%                                   angle:      center angle of the
%                                               stimulus can be []
%                                   stimulus:   stimulus struct containing
%                                               all stimuli info in imExp
%                                   fileInfo:   structure containg all file
%                                               information in the imExp
%
% OUTPUTS:                  surroundOriIndex:   metric that compares the
%                                               two cross orientations with
%                                               the iso-orientation
%                           surroundGains:      array of gains of each
%                                               conditions response 
%                                               relative to the center only
%                                               response
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% CALL AREA CALCULATOR AND LOCATE MAX CENTER AREA INDEX %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Call the area calculator to return the areas for all angles and all
% conditions of the surround
[meanAreas, ~, roiKeys] = areaCalculator(signalMaps, roiSetNum, roiNum,...
                                        stimulus, fileInfo, framesDropped);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% PARSE THE ANGLE INPUT ARGUMENT %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if the user has not supplied an angle we will try to locate the max
% center angle from the mean Areas. The max area angle currently depends
% on cellType
if isempty(angle)
    switch cellTypeOfInterest
        case 'pyr'
            % use cellfun to get max area angle (sum the c0 c1 and c2)                                  
            [~, maxIndex] = max(cellfun(@(x) sum(x(1:3)), meanAreas));
        case 'som'
            % use cellfun to get max area angle (sum the c0 and I)                                  
            [~, maxIndex] = max(cellfun(@(x) (x(1)+x(4)), meanAreas));
    end

    % convert the maxIndex into an angle using the roiKeys returned from
    % the area calculator
    maxAreaAngle = roiKeys{maxIndex};
    
    angle = maxAreaAngle;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% CALCULATE THE SURROUND ORIENTATION INDEX %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We calculate the surround orientation index. It is independent of the
% cellType

% locate the angle within the key set and return the index
angleIndex = (cell2mat(roiKeys)==angle);

% obtain the meanAreas for this index
meanAngleAreas = meanAreas{angleIndex};

surroundOriIndex = (mean(meanAngleAreas(2:3))-meanAngleAreas(4))/...
                    (mean(meanAngleAreas(2:3))+meanAngleAreas(4));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% CALCULATE THE SURROUND GAINS %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% simply divide all values by the center only to get the gains
surroundGains = meanAngleAreas./meanAngleAreas(1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% CALCULATE THE SUPPRESSION INDEX %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% determined as the (centerOnly-Iso)/centerOnly for pyramidal cells and as 
% (centerOnly-mean(crosses))/center only for SOM cells
switch cellTypeOfInterest
    case 'pyr'
        suppressionIndex =...
            (meanAngleAreas(1)-meanAngleAreas(4))/meanAngleAreas(1);
    case 'som'
        suppressionIndex =...
           (meanAngleAreas(1)-mean(meanAngleAreas(2:3)))/meanAngleAreas(1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

