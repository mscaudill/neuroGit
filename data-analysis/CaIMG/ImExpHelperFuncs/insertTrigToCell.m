%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%copyright (c) 2012  Matthew Caudill
%
%this program is free software: you can redistribute it and/or modify
%it under the terms of the gnu general public license as published by
%the free software foundation, either version 3 of the license, or
%at your option) any later version.

%this program is distributed in the hope that it will be useful,
%but without any warranty; without even the implied warranty of
%merchantability or fitness for a particular purpose.  see the
%gnu general public license for more details.

%you should have received a copy of the gnu general public license
%along with this program.  if not, see <http://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [insertedCell] = insertTrigToCell(indexes, cellArray)
% insertTrigToCell will insert a trigger name of 'missedTrigger' into a
% cell array of imageFileNames. 

% create a new cell that is the size of the incoming cell + the number of
% indexes to insert the string missedTrigger at
newCell = cell(1,numel(cellArray)+numel(indexes));

% Place the string 'missedTrigger' at each of these indexes
newCell(indexes) = {'missedTrigger'};

% create a logical cell from new cell that relays back whether a cell is
% empty
emptyLogical = cellfun(@isempty, newCell);

% set the empty elements to the original user supplied cell
newCell(~emptyLogical==0) = cellArray;

% rename
insertedCell = newCell;
end

