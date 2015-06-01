function singleCSTuningCurve(cellTypeOfInterest,roiSet,roiNum,...
                             responsePatternOfInterest)
% csTuningCurves generates population touning curves for the center and
% surround and plots them centered and together.
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
%
% INPUTS:          cellTypeofInterest: the cell type the user
%                                      wishes to plot ('pv', 'pyr', 'gad2')
%
% OUTPUTS:         NONE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL MULTIIMEXPLOADER %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Although we only load a single imExp for this script we can still use the
% multiloader. It will likely throw an error if user selects more than 1
% file
loadedImExp = multiImExpLoader('analyzed',{'cellTypes',...
                                'signalClassification',...
                                'areaMetrics', 'signalMaps'});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% EXTRACT CLASSIFICATION, AREAS, & RESPONSE TYPES %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Note we recast all the variables below as cells since scsFit and
% classifiers requires cells and not arrays

% obtain the cellTypes; note only 1 exp so we use the notation {1}
cellType = {loadedImExp{1}.cellTypes{roiSet}{roiNum}};

% error check the cellType to make sure it matches the one of interest
if ~strcmp(cellTypeOfInterest,cellType{1})
    errordlg(['The cell type of this cell is '...
                ,cellType{1}]);
    error('Cell type does not match');
end

% obtain the classification it needs to be a cell in cell in order to be
% evaluated by scsClassifier so cast it as such {1}{1}
classification{1}{1} = ...
    loadedImExp{1}.signalClassification.classification{roiSet}{roiNum};

% obtain the mean areas returns a 1 x numCells cell array
meanAreas = {loadedImExp{1}.areaMetrics.meanAreas{roiSet}{roiNum}};

%now call the pattern classifier resturning the cellTypes and
%responsePattern
[~,responsePattern]=scsPatternClassifier(cellTypeOfInterest,...
                                                     cellType,...
                                                     classification);
% error check the responsePattern to make sure it matches the one of interest
if responsePatternOfInterest ~= responsePattern
    errordlg(['The response pattern of this cell is '...
                ,num2str(responsePattern)]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% OBTAIN MAP KEYS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%obtain the angles that the imExp contains
signalMaps = loadedImExp{1}.signalMaps;
mapKeys = cell2mat(signalMaps{1}{1}.keys);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% OBTAIN CENTER AND SURROUND AREAS %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Each of the 1x8 cells in filtered areas contains a 5-el array for the
% five stimulus conditions. we need to use cellfun to extract the first
% element from each array (i.e. the center only condition)
% The areas are stored as 1x8 cells within a larger cell array over rois.
% We extract for each roi the 1x8 cell containing the 5 els and extract the
% first element. This requires a nested cellfun call
centerAreas = cellfun(@(g) cellfun(@(t) t(1), g),...
                            meanAreas, 'UniformOut',0); 
switch cellTypeOfInterest
    case 'pyr'
        % Obtain the max cross surrounds taking the mean of the two crosses
        surroundAreas = cellfun(@(g) cellfun(@(t) mean(t(2:3)), g),...
                            meanAreas, 'UniformOut',0);
    case 'som'
        % obtain the iso-areas
        surroundAreas = cellfun(@(g) cellfun(@(t) t(4), g),...
                            meanAreas, 'UniformOut',0);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% COMPUTE SHIFTED AREA CURVES %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will now shift each tuning curve to the center of the array using
% shiftArray function. 
% First we find the max and shift using shiftArray
alignedCenterAreas = cellfun(@(h) shiftArray(h,'shiftIndex',3),...
                             centerAreas, 'UniformOut',0);
alignedSurroundAreas = cellfun(@(h) shiftArray(h,'shiftIndex',3),...
                             surroundAreas,'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% CALL FITDATA WITH RELAXED DOUBLE GAUSSIAN METHOD %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now will fit the center and cross tunning curves with a double
% Gaussian
% Call the wrapper scsFit using method two with padding on the meanCenter
% [centerFitParams, centerXFit, centerDataFit] = ...
%                             fitData('gaussian',mapKeys,alignedCenterAreas{1});
% % Do the same for the cross data                        
% [surroundFitParams, surroundXFit, surroundDataFit] = ...
%                         fitData('gaussian',mapKeys,alignedSurroundAreas{1});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Plot the center Fit
% plot(centerXFit{1}, centerDataFit{1},'b-')
% plot(mapKeys, alignedCenterAreas)
%assignin('base','surroundFitParams',surroundFitParams)
% plot(surroundXFit, surroundDataFit,'k-')
% hold on
plot(mapKeys, [alignedSurroundAreas{:}])
hold off
end

