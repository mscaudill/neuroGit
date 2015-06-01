function [ averageImage] = multiStackAverager(stacks, imageType)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Start by casting all of the image stacks as double arrays for array
% manipulation
if imageType=='double'
    doubleImageStacks = cellfun(@(x) cast(x,'double'), stacks,...
                                'UniformOut',0);
end

% now we begin to average (average first over each stack
meanDoubles = cellfun(@(t) mean(t,3), doubleImageStacks, 'UniformOut',0);

%now average across stacks
averageImage = cast(mean(cat(3,meanDoubles{:}),3),'uint;
end

