function [ combinedStruct ] = structJoiner( varargin )
%structJoiner takes a list of n structures with m fields and returns a
%conbined n-array of structures with m fields. (eg) inputs:
% structArray1 = 2x3, structArray1 = 5x3 yields the outputs 7x3 structArray
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% PERFORM CHK OF INPUT STRUCTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get all of the user inputs
inputStructs = varargin{:};

% We need to check 
% 1. that each of the inputs is a structure
% 2. That all the structs contain the same fields
% 3. That the second dimension of all the structs are the same

% Chk that all inputs are structs
try 
    any(cellfun(@(r) isstruct(r), inputStructs))
    catch MEstruct
            throw(MEstruct)
end

% chk that all inputs contain the same fields
% get the fieldNames of each structure
fieldNames = cellfun(@(e) fieldnames(e), inputStructs, 'UniformOut',0);
for name=1:numel(fieldNames)
    % Do a cell comparsion of all cells to the first cell of fieldNames to
    % ensure each structure has exactly the same fieldnames
    if ~any(strcmp(fieldNames{1},fieldNames{name}))
        error('structJoiner:NonMatchingFieldNames',...
            'Structure Arrays must have the same fields to be joined');
    end
end


% Check that the second dimension is consistent across all input structures
colSizes = [];
% get the max size of the substructures in the structures to be joined
for struct=1:numel(inputStructs)
    colSizes = [colSizes, max(structfun(@(field) length(field),...
               inputStructs{struct}))];
end
% Chk that the max substructure size is the same for all structures to be
% joined by evaluating the mnumber of elements in unique
if numel(unique(colSizes)) > 2;
   error('structJoiner:NonMatchingStructSizes',...
        'Structure Arrays must have the same number of cols to be joined');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% COMBINE THE STRUCTURES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now that we have equal size structures with all the same fields we can
% join our structures
% get the fieldNames for the first structure, remember we have chkd they
% are all equal
fieldNames = fieldNames{1};
% Now loop through the fieldNames and concatenate the structures togehter
for fieldName = 1:numel(fieldNames)
    % obtain a cell of substructures e.g. get all the stimulus substructs 
    structCellField = cellfun(@(o) o.(fieldNames{fieldName}),...
                              inputStructs, 'UniformOut',0);
    % now concatenate the stimulus substructs and place them into the
    % combined structure
    combinedStruct.(fieldNames{fieldName}) = cat(1,structCellField{:});
end



end

