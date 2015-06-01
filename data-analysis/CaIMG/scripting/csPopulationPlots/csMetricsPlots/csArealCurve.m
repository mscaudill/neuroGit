function csArealCurve(cellTypeOfInterest)
% csArealCurve plots the mean of the five cs stimlus conditions across all
% cells matching the cellTypeof Interest
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
    areas{file} = loadedImExps{file}.areaMetrics.meanAreas;
    
    % obtain the maxAreaAngles
    maxAngles{file} = ...
         loadedImExps{file}.signalClassification.maxAreaAngle;
    
    %now call the pattern classifier resturning the cellTypes and
    %responsePatterns for each imExp
    [expCellTypes{file},responsePatterns{file}]=scsPatternClassifier(...
                                                 cellTypeOfInterest,...
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

% combine the areas across all the files
combFileAreas = [areas{:}];
% combine the areas across the roiSets
allAreas = [combFileAreas{:}];

%combine the maxArea angles across the imExp files
combAreaAngles=[maxAngles{:}];
% combine all the roiSets toghether
maxAreaAngles = [combAreaAngles{:}];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% FILTER BY CELL TYPE & RESPONSE TYPE %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% call the function csAreaFilter and return the filtered results (note we
% pass along the cellTypeofInterest and keep only responsePattern
% consistent with the cellTypeofInterest. Please see identifyScsPattern
switch cellTypeOfInterest
    case 'pyr' % For pyrs the cellTypeOfinterest has response pattern 4
        filteredAreas = csCellArrayFilter(allAreas,allCellTypes,...
                            cellTypeOfInterest,...
                            allResponsePatterns,[3,4]);

        filteredThetas = csCellArrayFilter(maxAreaAngles,allCellTypes,...
                            cellTypeOfInterest,...
                            allResponsePatterns,[3,4]);
    case 'som' % For soms the cellTypeOfinterest has response pattern 5
        filteredAreas = csCellArrayFilter(allAreas,allCellTypes,...
                            cellTypeOfInterest,...
                            allResponsePatterns,[5]);

        filteredThetas = csCellArrayFilter(maxAreaAngles,allCellTypes,...
                            cellTypeOfInterest,...
                            allResponsePatterns,[5]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% OBTAIN MAX ANGLE INDICES %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Our imExp_Analyzed contains the max area angle. The angle at which the
% center+cross1+cross2 angles are the greatest (not necessarily where the
% center alone is greatest). We have rtrieved and stroed these values to
% filteredTheatas
% convert to array
 thetaMaxs = cell2mat(filteredThetas);

 % we no convert these angles into indexes to obtain the maxAngleIndices
 angleSteps = mapKeys(2)-mapKeys(1);
 maxAngleIndices = (thetaMaxs./angleSteps)+1; % add 1 to index for 0 angle
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% OBTAIN MAX AREA CURVES %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now loop through the filetered areas and extract the array of areas
% corresponding to the maxAngle. We normalize each cell to the maximum
% area recorded for that cell (03-05-2014 MSC)
for roi = 1:numel(filteredAreas)
    areaCurve{roi} = filteredAreas{roi}{maxAngleIndices(roi)}/...
        max(filteredAreas{roi}{maxAngleIndices(roi)});
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% CONCATENATE THE AREA CURVES %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now concatenate the area curves into a matrix measuring numCells x
% numConds (ex 41 cells x 5 conds) using vertcat
areaMatrix = vertcat(areaCurve{:});

% now compute mean and standard error of the mean along the row dimension
meanAreaCurve = mean(areaMatrix,1);
seAreaCurve = std(areaMatrix,1)/sqrt(size(areaMatrix,1));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create a new figure by getting the number of current figures
numFigs=length(findall(0,'type','figure'));

% create a figure one greater than the number of open figures
h2 = figure(numFigs+1);

% swap cols so that conds now read center alone. cross1 iso cross2
% surrAlone
meanAreaCurve([3,4]) = meanAreaCurve([4,3]);
seAreaCurve([3,4]) = seAreaCurve([4,3]);

% Compute SOI value. Note this value depends on cellTypeOfInterest. For
% pyrs it is  0.5*(cross1+cross2)/iso and cor SOM cells it is
% iso/mean(cross1,cross2) remember we switched order above to  center
% alone. cross1 iso cross2 surrAlone
soi = (mean([meanAreaCurve(2), meanAreaCurve(4)])-meanAreaCurve(3))/...
        (mean([meanAreaCurve(2), meanAreaCurve(4)])+meanAreaCurve(3));

% Plot all but center only
errorbar(meanAreaCurve(2:end), seAreaCurve(2:end),'-bo')
hold on
% now plot center only separately
errorbar(2, meanAreaCurve(1), seAreaCurve(1),...
    'or')

set(gca,'XTick',(1:1:size(areaMatrix,2)-1))
        set(gca,'XTickLabel',{'C1', 'ISO', 'C2', 'SO'})
        
ylim([0,1])

title (['Population Area Curve n = ', num2str(size(areaMatrix,1)),...
        ', SOI = ',num2str(soi)])
end

