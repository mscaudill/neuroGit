function [combCellTypes, responsePatterns] = ...
                            scsPatternClassifier(cellTypeOfInterest,...
                                                cellTypes, classification)
%                        
% scsPatternClassifier takes the fields cellTypes and classification for a
% given imExp_analyzed and returns a combined cellType cell array and a
% responsePattern scalar. The response pattern scalar represnts the 5
% element response vector uniquely.
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
% INPUTS:
%
% OUTPUTS:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% CONCATENATE ALL THE CELLTYPES/CLASSIFICATIONS %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Concatenate the cell types
combCellTypes = [cellTypes{:}];
% Concatenate the response classifications if there are more than one. We
% do this becasue if there is only one we want it to remain a cell and not
% converted to an array
assignin('base','classification', classification)

imExpClassifications = [classification{:}];

% perform check to make sure all calssifications are logicals using cellfun
imExpClassifications = cellfun(@(w) logical(w),...
                               imExpClassifications, 'UniformOut', 0);

% call identifySCSPatterm function to assing a scalar to the response
% pattern
responsePatterns = cellfun(@(y) identifyScsPattern(cellTypeOfInterest,y),...
                            imExpClassifications);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


end

