function isoCrossScatter(cellTypesofInterest)
% isoCrossScatter creates a population scatterPlot of cross areas
% vs center areas.
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
% INPUTS:          cellTypesofInterest: a cell array of cell types
%                                      wishes to plot {'pyr', 'som'}
%
% OUTPUTS:         NONE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% MAIN LOOP OVER CELLTYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for cellTypeIndex = 1:numel(cellTypesofInterest)
    cellTypeofInterest = cellTypesofInterest{cellTypeIndex};
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
    [expCellTypes{file},responsePatterns{file}]=scsPatternClassifier(...
                                                 cellTypeofInterest,...
                                                 cellTypes{file},...
                                                 classification{file});
                                             
    % we also need the max area angles
    maxThetas{file} = ...
        loadedImExps{file}.signalClassification.maxAreaAngle;
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

combFileThetas = [maxThetas{:}];

allMaxThetas = [combFileThetas{:}];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% FILTER BY CELL TYPE & RESPONSE TYPE %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% call the function csAreaFilter and return the filtered results (note we
% pass along the cellTypeofInterest and keep only responsePattern 4
switch cellTypeofInterest
    case 'pyr'
        respPattern = [3,4];
    case 'som'
        respPattern = [4,5];
end
    
filteredAreas{cellTypeIndex} = csCellArrayFilter(allAreas,allCellTypes,...
                            cellTypeofInterest,...
                            allResponsePatterns,respPattern);
filteredThetas{cellTypeIndex} = csCellArrayFilter(allMaxThetas,allCellTypes,...
                            cellTypeofInterest,...
                            allResponsePatterns,respPattern);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% OBTAIN CROSS AND ISO ORIENTED AREAS %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Each of the 1x8 cells in filtered areas contains a 5-el array for the
% five stimulus conditions. we need to use cellfun to extract the first
% element from each array (i.e. the center only condition)
% The areas are stored as 1x8 cells within a larger cell array over rois.
% We extract for each roi the 1x8 cell containing the 5 els and extract the
% first element. This requires a nested cellfun call
isoAreas{cellTypeIndex} = cellfun(@(g) cellfun(@(t) t(4)/(2*7.81), g),...
                            filteredAreas{cellTypeIndex}, 'UniformOut',0); 

% now obtain the cross-oriented areas
crossAreas{cellTypeIndex} = cellfun(@(h) cellfun(@(s) mean(s(2:3))/(2*7.81), h),...
                                filteredAreas{cellTypeIndex},...
                                'UniformOut',0);
                           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% RETRIEVE MAX AREA ANGLES FROM SIGNALCLASSIFICATION %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Our imExp_Analyzed contains the max area angle. The angle at which the
% center+cross1+cross2 angles are the greatest (not necessarily where the
% center alone is greatest). We will retrieve these from the
% signalClassification structure
 thetaMaxs{cellTypeIndex} = cell2mat(filteredThetas{cellTypeIndex});

 % we no convert these angles into indexes to obtain the center areas and
 % isoAreas for these angles
 angleSteps = mapKeys(2)-mapKeys(1);
 % To get to an index from the angle just divide by angle steps and add 1.
 maxIndices{cellTypeIndex} = thetaMaxs{cellTypeIndex}./angleSteps + 1;
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% OBTAIN MAX CENTER AREA USING MAXINDICES %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract the max center areas . We do this by looping over the number of 
% cells for this cellType and get the centerAreas for that roi that are the
% largest using the maxIndices we just calculated

for roi=1:numel(isoAreas{cellTypeIndex})
    maxIsoAreas{cellTypeIndex}(roi) =...
        isoAreas{cellTypeIndex}{roi}(maxIndices{cellTypeIndex}(roi));

    maxCrossAreas{cellTypeIndex}(roi) =... 
        crossAreas{cellTypeIndex}{roi}(maxIndices{cellTypeIndex}(roi));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end
%%%%%%%%%%%%%%%%%%%%%% END FOR LOOP OVER CELLTYPES %%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% OBTAIN MEAN AND STD OF AREAS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
meanMaxIsoArea = cellfun(@(x) mean(x), maxIsoAreas);
semMaxIsoArea = cellfun(@(x) std(x),...
                        maxIsoAreas)./sqrt(numel(maxIsoAreas));

meanMaxCrossArea = cellfun(@(x) mean(x), maxCrossAreas);
semMaxCrossArea = cellfun(@(x) std(x),...
                            maxCrossAreas)./sqrt(numel(maxCrossAreas));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define some colors
colors = {'b','r'};
errorColors = {'b^','r^'};
% loop over the cellTypes for plotting
for cellType = 1:numel(cellTypesofInterest)
    hold on
    % scatter the areas for each cell type 
    scatter(maxIsoAreas{cellType}, maxCrossAreas{cellType}, 50,...
        colors{cellType})
    
    scatter(meanMaxIsoArea(cellType),meanMaxCrossArea(cellType),...
        150,colors{cellType},'^','fill')
    % call the exchange function errorbarxy to plot mean and sems
    errorbarxy(meanMaxIsoArea(cellType), meanMaxCrossArea(cellType),...
        semMaxIsoArea(cellType), semMaxCrossArea(cellType),[],[],...
        errorColors{cellType},colors{cellType})
end

xlabel('Iso Area')
ylabel('Cross Area')
refline(1,0)

if numel(cellTypesofInterest) == 2;
title(['Iso/Cross Scatter (', cellTypesofInterest{1}, ') n = ',...
        num2str(numel(maxIsoAreas{1})),...
        ' (',cellTypesofInterest{2},') n= ',...
        num2str(numel(maxIsoAreas{2}))]);
elseif numel(cellTypesofInterest) == 1;
    title(['Gain Scatter (', cellTypesofInterest{1}, ') n = ',...
        num2str(numel(maxIsoAreas{1}))]);

end
hold off

end

