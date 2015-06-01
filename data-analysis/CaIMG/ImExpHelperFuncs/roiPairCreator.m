function [ indexMatrix ] = roiPairCreator( nestedCell )
% roiPair converter takes a nested cell of information stored using the
% {roiSet}{roiNumber} convention and constructs a matrix of roiIndices. The
% first colum of the matrix contains the set indices, here referred to as
% major Indices and the second column contains the roiNumber indices, here
% referred to as minor Indices. Please see ex below
% 1 1
% 1 2
% 2 1
% 4 1
% Where the first column contains the majorIndex and the second column
% contains the minorIndex. 
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

%%%%%%%%%%%%%%%%%%%%%%%% OBTAIN UNIQUE MAJOR INDICES %%%%%%%%%%%%%%%%%%%%%%
% We first need to get the unique major indices. In the example above this
% would be [1 2 4]

% Locate within the nested cell array the non-empty sets/cells
nonEmptySets = ~cellfun(@isempty, nestedCell);

% now get the indices (i.e. the majorIndex) for these non-empty cells
majorIndices = find(nonEmptySets);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%% OBTAIN THE MINOR INDICES %%%%%%%%%%%%%%%%%%%%%
% We start by counting the number of elements in each set/cell. In our
% example above this gives [ 2 1 0 1]
minorIndices =  cellfun(@(x) numel(x), nestedCell);
% Now take only the ones that are non-zero (remember we ignore empty sets)
minorIndices = minorIndices(minorIndices>0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%% REPEAT MAJOR INDICES BY MINOR INDICES %%%%%%%%%%%%%%%%%%
% In our example we have major indices [ 1 2 4] and minorIndices [ 2 1 1]
% We need to repeat the major indices and "count" up the minor indices to
% construct a matrix like this:
% 1 1
% 1 2
% 2 1
% 4 1

% First repeat each majorIndex by the number of times that matches the
% minor index (i.e. 1 need to be repeated 2x. We need to deal with the
% possibilty that all rois were drawn on only one of the sets becasue the
% below vectorization technique fails in that case

% Is there only one major index? If not then we use vectorized method
if numel(majorIndices) > 1
    % A trick to do this rapidly (i.e. vectorized) is to
    % 1. cocatenate a one onto the beginning of minorIndices [1 2 1 1]
    % 2. take the one to end-1 elements of minorIndices [1 2 1]
    % 3. take the cumaltive sum of the elecemts [1 3 4]
    % 4. create an index array index([ 1 3 4]) = 1 yields [ 1 0 1 1]
    index(cumsum([1 minorIndices(1:end-1)])) = 1;
    % we need to take care of the case in which the last major Index needs
    % repeating. The above assumes the last major index occurs once
    if minorIndices(end) ~= 1
        index = [index, 0*ones(1,minorIndices(end)-1)];
    end
    % now take the cumsum of the index array [ 1 1 2 3]
    index = cumsum(index);

else
    % If only one major index then  index is simply an array of ones(i.e.
    % (i.e. we always pull from the same majorIndex)
    index = ones(1,minorIndices);   
end

% use the index array to index the majorIndices majorIndices([ 1 1 2 3])=
% [1 1 2 4]. Notice that this repeats the major Indices by minor indices
majorIndices = majorIndices(index);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%% COUNT UP THE MINOR INDICES %%%%%%%%%%%%%%%%%%%%%%%%%
% We now have the majorIndices but we need to count up the minor indices [2
% 1 1] so we get the following matrix
% 1 1
% 1 2
% 2 1
% 4 1
% We start by creating a cell array with linearly spaced arrays matching
% the number of elements in the nested cell array. In our example this
% would be {[ 1 2], [1], [], [1]}
minorIndexArrays = cellfun(@(x) linspace(1,numel(x),numel(x)),...
                        nestedCell, 'UniformOut', 0);
                    
% In older versions of matlab linspace(1,0,0) gives 0. Newer versions
% return an [] array so we need to handle this here by removing zeros.
minorIndexArrays = cellfun(@(x) x(x>0), minorIndexArrays, 'UniformOut',0);
                    
% Now we simply concatenate these together [ 1 2 1 1]
minorIndices = cat(2,minorIndexArrays{:});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%% CONCATENATE MAJOR & MINOR INDICES AND ROTATE %%%%%%%%%%%%%
% Concatenate the major and minor inices and rotate to complete our matrix
% of indices
indexMatrix = [majorIndices;minorIndices]';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


end

