function [ maxProjection] = multiStackMaxIntensity(stacks, imageType)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Start by casting all of the image stacks as double arrays for array
% manipulation
if ~strcmp(imageType,'double')
    doubleImageStacks = cellfun(@(x) cast(x,'double'), stacks,...
                                'UniformOut',0);
end

% now we begin to average (max first over each stack)
maxDoubles = cellfun(@(t) max(t,[],3), doubleImageStacks, 'UniformOut',0);

%now mean across stacks
maxProjection = cast(max(cat(3,maxDoubles{:}),[],3),'uint16');
%maxProjection = cast(mean(cat(3,maxDoubles{:}),3),'uint16');

%assignin('base','maxProjection',maxProjection)

end

