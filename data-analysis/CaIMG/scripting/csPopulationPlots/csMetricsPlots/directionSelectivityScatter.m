function directionSelectivityScatter(cellTypeofInterest)
% directionSelectivityScatter creates a scatter of the two
% cross-orientations for each cell in our poulation. We are looking for off
% diagonal placement indicating the direction of one cross is preferred to
% the other.
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL MULTIIMEXPLOADER %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We need the cell types from each imExp_analyzed and the signalMetrics
% structure which contains the surround for each cell. We also
% need the signal classification becasue we are only interest in cells with
% a center response
loadedImExps = multiImExpLoader('analyzed',{'cellTypes',...
                                'signalClassification', 'signalMetrics'});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% EXTRACT CLASSIFICATION, GAINS, AND CELLTYPES %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for file=1:numel(loadedImExps)
    % obtain the cellTypes
    cellTypes{file} = loadedImExps{file}.cellTypes;
    
    % obtain the classification
    classification{file} = ...
        loadedImExps{file}.signalClassification.classification;
    
    % obtain the mean areas
    gains{file} = loadedImExps{file}.signalMetrics.surroundGains;
    
    %now call the pattern classifier resturning the cellTypes and
    %responsePatterns for each imExp
    [expCellTypes{file},responsePatterns{file}]=scsPatternClassifier(...
                                                 cellTypes{file},...
                                                 classification{file});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%  PERFORM CONCATENTATION %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now ready to concatenate all the cell types responsePatterns and
% gains across all the roiSets

allCellTypes = [expCellTypes{:}];

allResponsePatterns = [responsePatterns{:}];

combFileGains = [gains{:}];

allGains = [combFileGains{:}];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% FILTER BY CELL TYPE & RESPONSE TYPE %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% call the function csCellArrayFilter and return the filtered results (note
% we pass along the cellTypeofInterest and keep only responsePattern 4
filteredGains = csCellArrayFilter(allGains,allCellTypes,...
                                    cellTypeofInterest,...
                                    allResponsePatterns,[4]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% EXTRACT GAINS OF THE TWO CROSS SURROUNDS %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The gains area a cell of 1x5 arrays containing each condition area
% divided by the center condition area. Since we are interested in the
% cross orientation gains, we will take the second and third values from
% each array
cross1Gains = cellfun(@(y) y(2), filteredGains);
cross2Gains = cellfun(@(y) y(3), filteredGains);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scatter(cross1Gains,cross2Gains)
title(['Cross1 vs Cross2 gains n = ',num2str(numel(cross1Gains))])
refline(1,0)
refline(.7,0)
refline(1.3,0)

end

