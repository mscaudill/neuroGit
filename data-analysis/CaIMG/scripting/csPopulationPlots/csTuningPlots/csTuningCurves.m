function csTuningCurves(cellTypeofInterest,varargin)
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
%                   varargin: option to normalize the outputted curve
%
% OUTPUTS:         NONE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARSE VARARGIN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2
    normalize = false;
elseif nargin == 2
    normalize = true;
else 
    errordlg('Too many inputs')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL MULTIIMEXPLOADER %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
loadedImExps = multiImExpLoader('analyzed',{'cellTypes',...
                                'signalClassification',...
                                'areaMetrics', 'signalMaps'});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% EXTRACT CLASSIFICATION, AREAS, & RESPONSE TYPES %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for file=1:numel(loadedImExps)
    % obtain the cellTypes
    cellTypes{file} = loadedImExps{file}.cellTypes;
    
    % obtain the classification
    classification{file} = ...
        loadedImExps{file}.signalClassification.classification;
    
    % obtain the mean areas
    meanAreas{file} = loadedImExps{file}.areaMetrics.meanAreas;
    
    %now call the pattern classifier resturning the cellTypes and
    %responsePatterns for each imExp
    [expCellTypes{file},responsePatterns{file}]=scsPatternClassifier(cellTypeofInterest,...
                                                 cellTypes{file},...
                                                 classification{file});
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% OBTAIN MAP KEYS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%obtain the angles that the imExp contains
signalMaps = loadedImExps{1}.signalMaps;
mapKeys = cell2mat(signalMaps{1}{1}.keys);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%  PERFORM CONCATENTATION %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now ready to concatenate all the cell types responsePatterns and
% mean areas across all the imExps

allCellTypes = [expCellTypes{:}];

allResponsePatterns = [responsePatterns{:}];

combFileAreas = [meanAreas{:}];

allAreas = [combFileAreas{:}];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% FILTER BY CELL TYPE & RESPONSE TYPE %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% call the function csAreaFilter and return the filtered results (note we
% pass along the cellTypeofInterest and keep only responsePatterns
% pertinent for the cellTypeOfInterest (plwese see scsPatternClassifier)

switch cellTypeofInterest
    case 'pyr' % If pyramidal then we are interested in response type 4
        filteredAreas = csCellArrayFilter(allAreas,allCellTypes,...
                                            cellTypeofInterest,...
                                            allResponsePatterns,[4]);
    case 'som' %If som then we are interested in response patterns [4,5]
        filteredAreas = csCellArrayFilter(allAreas,allCellTypes,...
                                            cellTypeofInterest,...
                                            allResponsePatterns,[4,5]);
end
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
                            filteredAreas, 'UniformOut',0);
                        
% The surround areas for plotting will depend on the cellTypeofInterest
switch cellTypeofInterest
    case 'pyr'
        %Obtain the mean of the two crosses for surround tuning opf pyrs
        surroundAreas = cellfun(@(g) cellfun(@(t) max(t(2:3)), g),...
                                            filteredAreas, 'UniformOut',0);
    case 'som'
        % obtain the iso-orientation condition to determine tuning of soms
        surroundAreas = cellfun(@(g) cellfun(@(t) t(4), g),...
                                            filteredAreas, 'UniformOut',0);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% COMPUTE MEAN CENTER AREA CURVE %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will now shift each tuning curve to the center of the array using
% shiftArray function. 
% First we find the max and shift using shiftArray
alignedCenterAreas = cellfun(@(h) shiftArray(h,'shiftIndex',3), centerAreas,...
                             'UniformOut',0);
alignedSurroundAreas = cellfun(@(h) shiftArray(h,'shiftIndex',3), surroundAreas,...
                             'UniformOut',0);

% now we compute the mean and stadard error across all the area vectors for
% each cell. We start by placing all the area vectors for each cell into a
% matrix.

 %This makes a numCells x angles matrix for the center areas and crossAreas
centerMatrix = vertcat(alignedCenterAreas{:});
surroundMatrix = vertcat(alignedSurroundAreas{:});

% now compute the mean and standard error along the row dimension
meanCenter = mean(centerMatrix,1);
% Compute standard error of the mean
seCenter = std(centerMatrix,1)/sqrt(size(centerMatrix,1));

% do the same for the cross areas
meanSurround = mean(surroundMatrix,1);
seSurround = std(surroundMatrix,1)/sqrt(size(surroundMatrix,1));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% CALL FITDATA WITH RELAXED DOUBLE GAUSSIAN METHOD %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now will fit the center and cross tunning curves with a double
% Gaussian
% 
% [centerFitParams, centerXFit, centerDataFit]= ...
%                             fitData('doubleGaussian',...
%                             mapKeys, meanCenter, 'initGuess',...
%                             [1 90 20 .5 .2]);

[centerFitParams, centerXFit, centerDataFit]= ...
                            fitData('relaxedDoubleGaussian',...
                            mapKeys, meanCenter, 'initGuess',...
                            [1 90 30 .5 270 .4]);

[surroundFitParams, surroundXFit, surroundDataFit]= ...
                            fitData('relaxedDoubleGaussian',...
                            mapKeys, meanSurround, 'initGuess',[1 90 25 .5 270 5]);
                        %[1 90 25 .5 .2]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% normalize if requested
if normalize
    normCenterFactor = max(meanCenter);
    normSurroundFactor = max(meanSurround);
    % normalize the meanCenter and meanSurround arrays
    meanCenter = meanCenter./normCenterFactor;
    seCenter = seCenter./normCenterFactor;
    
    meanSurround = meanSurround./normSurroundFactor;
    seSurround = seSurround./normSurroundFactor;
    
    % normalize the dataFits
    centerDataFit = centerDataFit/normCenterFactor;
    surroundDataFit = surroundDataFit/normSurroundFactor;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The data that will be plotted depends on the cellTypeofInterest
switch cellTypeofInterest
    % For pyramidal cells we will plot both the center and surround 
    % (i.e. mean of cross orientation conditions) tuning curves and fits
    case 'pyr'
        % Plot centerAreas curve
        errorbar(mapKeys,meanCenter,seCenter, 'ob')
        hold on
        % Plot the center Fit
        plot(centerXFit, centerDataFit,'b-')

%         % Plot the surroundAreas curve
%         errorbar(mapKeys,meanSurround, seSurround,'or')
%         hold on
%         % Plot the surround Fit
%         plot(surroundXFit{1}, surroundDataFit{1},'r-')
%         hold off
    
    % For Som cells we only plot the iso-orientation fits
    case 'som'
        % Plot the surroundAreas curve
        errorbar(mapKeys,meanSurround, seSurround,'or',...
                 'MarkerFaceColor','r')
        hold on
        % Plot the surround Fit
        plot(surroundXFit, surroundDataFit,'r-')
        hold off
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% PLOT TITLE & RETURNED RESULTS %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The title will be determined by the cellType of interest
switch cellTypeofInterest
    case 'pyr'
         title(['Center width = ',...
                num2str(centerFitParams(3)*sqrt(2*log(2))),...
                ' Surround width = ',...
                num2str(surroundFitParams(2)*sqrt(2*log(2))),...
                ' n = ', num2str(size(filteredAreas,2))]);

    case 'som'
        title(['SOM Cell Tuning Curve',... 
       ' HWHM = ', num2str(surroundFitParams(3)*sqrt(2*log(2))),...
       ' n = ' num2str(size(filteredAreas,2))]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

set(gca,'XTick',mapKeys)
xlabel('Angle (degrees)')
ylabel('Area')

end

