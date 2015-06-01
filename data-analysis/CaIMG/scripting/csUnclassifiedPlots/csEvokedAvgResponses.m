function [matrixMap] = csEvokedAvgResponses(imExp, chNumber, runState)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% call cs map
[imagesMap, ~] = csMap(imExp,chNumber, runState);

% calculate mean stacks of each surround condition for each center angle
% get cell of all map values (1x8 cell)
mappedImages = imagesMap.values;





end

