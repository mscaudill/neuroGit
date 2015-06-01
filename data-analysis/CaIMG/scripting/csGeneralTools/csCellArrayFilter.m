function [ filteredCellArray ] = csCellArrayFilter(cellArray, allCellTypes,...
                                          cellTypeOfInterest,...
                                          allResponsePatterns,...
                                          responseTypesOfInterest)
%csCellArrayFilter takes a cell of array (eg. areas, or thetas gathered
%from a set of imExps and pulls out the cells that meet the cellType and
%responseType criteria
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
% INPUTS:          cellArray:     cell array of values gathered from a set 
%                                 of imExps
%                  cellType:      the cell type the user
%                                  wishes to filter by ('pv','pyr',...)
%                  responseType:  a scalar or vector of response to keep
%
% OUTPUTS:         filteredAreas: cell aray of areas meeting the cellType 
%                                 and responseType criteria 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% FILTER BY CELL TYPE & RESPONSE TYPE %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% obtain a logical array of cells matching the user selected cell type
typeLogical = ~cellfun(@isempty,...
                            strfind(allCellTypes,cellTypeOfInterest));

% construct a logical array of response types where response types match
% those in the vector responseTypes of interest. We can use ismember to
% quickly accomplish this task
responseLogical = ismember(allResponsePatterns,responseTypesOfInterest);

% Now we need to create a combined logical where the type is true and the
% response is true
filterLogical = logical(typeLogical==1 & responseLogical==1);

% now filter the areas cell pulling out the 1x8 cells that meet the above
% criteria
filteredCellArray = [cellArray(filterLogical)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


end

