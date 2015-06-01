function responsePatternHist(cellTypeOfInterest)
% responsePatternHist creates a histogram plot of response patterns for scs
% data determined by the function scsPatternClassifier. It uses uigetfile
% to allow users to select single or multiple imExps_analyzed.
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
%%%%%%%%%%%%%%%%%%%% EXTRACT CLASSIFICATION & CELLTYPES %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for file = 1:numel(loadedImExps)
    % obtain the cellTypes
    cellTypes{file} = loadedImExps{file}.cellTypes;
    
    % obtain the classification
    classification{file} = ...
        loadedImExps{file}.signalClassification.classification;
    
    % we are now ready to call the scsPatternClassifier
    [expCellTypes{file},responsePatterns{file}]=...
        scsPatternClassifier(cellTypeOfInterest, cellTypes{file},...
                                                 classification{file});
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% CONCATENATE ALL THE CELLTYPES & RESPONSE PATTERNS %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now ready to concatenate all the cell types across the imExps and
% all the response patterns across the imExps

allCellTypes = [expCellTypes{:}];

allResponsePatterns = [responsePatterns{:}];

% Get the possible responses from the cell Type: 'pyr' = [1:5], 'som' =
% [1:6]. Please see identifyScsPattern.m for more info
switch cellTypeOfInterest
    case 'pyr'
        uniqueResponsePatterns = [1:5];
    case 'som'
        uniqueResponsePatterns = [1:6];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% FILTER BY CELL TYPE & RESPONSE TYPE %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% call the function csCellArrayFilter and return the filtered results (note we
% pass along the cellTypeofInterest and all response patterns
cellofInterestResponses = csCellArrayFilter(allResponsePatterns,...
                                    allCellTypes,...
                                    cellTypeOfInterest,...
                                    allResponsePatterns,...
                                    uniqueResponsePatterns);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numOfCells = numel(cellofInterestResponses);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


hist(cellofInterestResponses,uniqueResponsePatterns)
title(['Histogram plot of ', cellTypeOfInterest, ' n = ',...
                            num2str(numOfCells)]);                        
end

