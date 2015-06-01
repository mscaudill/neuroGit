function [osi] = imOrientationSelectivity(signalMaps, roiSetNum,...
                                           roiNum, stimulus, fileInfo)
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
% imOrientationSelectivity calculates the osi value from the area below the
% curve uisng the trapezoidal rule.
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
% OUTPUTS:                          osi:      orientation selectivity index
%                                             using circular variance
%                                             according to Ringach 
%                                             Orientation Selectivity in 
%                                           Macaque V1... 2002 J. Neurosci)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% CALL THE AREA CALCULATOR %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We call the area calculator and return the mean areas and the roiKey
% angles
[meanAreas, ~, angles] = areaCalculator(signalMaps, roiSetNum, roiNum,...
                                        stimulus, fileInfo);

% convert the angles cell returned from area calculator into an array                                    
angles = cell2mat(angles);

if any(angles==Inf)
    angles(end) = [];
    meanAreas(end) = [];
end

meanAreas = cell2mat(meanAreas);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% CONVERT ANGLES TO RADIANS %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
anglesRads = pi/180*angles;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALCULATE OSI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
osi = abs(sum(meanAreas.*exp(2i*anglesRads)/sum(meanAreas)));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



end

