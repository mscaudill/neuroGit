function signalMap = optoResponse(droppedStacks, chNumber, currentRoi,...
                                  baselineFrames, neuropilRatio);
%optoResponse computes the response of a cell to laser or led stimulation
%alone.
%
% INPUTS                : droppedStacks, 3-d image stacks structure n
%                         trials X numConditions in size
%                       : roi, current roi to extract signal from
%                       : baselineFrames, frames for computing baseline
%                         fluorescence over
%                       : neuropil ratio, % amt of neuropil to subtract
%                       : chNumber containing images
% OUTPUTS
%                       : signalMap map object keyed on trial number
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
%%%%%%%%%%%%%%%%%% OBTAIN IMAGES CELL FROM IMAGESSTRUCT %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now obtain the images from the droppedStacks structure. We again
% rotate the structure first to keep the triggers ordered
imagesStruct = droppedStacks';
structSize = size(imagesStruct);
% Use the user inputted chNumber to extract all the images for that ch to a
% cell array
imagesCell = {imagesStruct(:,:).(['Ch',num2str(chNumber)])};
% since laser is shown every two trials remove the empty cells
imagesCell = imagesCell(~cellfun(@isempty, imagesCell));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% COMPUTE AVERAGE STACKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% group the images by trials
for trial = 1:structSize(1)/2
    % get the first 10 image stacks
    groupedImages{trial} = {imagesCell{1:10}};
    % pop off the first 10 after extracting group
    imagesCell(1:10)=[];
end

% concatenate trials along 4th dim
groupedImages = cellfun(@(x) cat(4,x{:}), groupedImages, 'UniformOut',0);

% lastly compute the mean along the 4th dim
meanStacks = cellfun(@(x) mean(x,4), groupedImages, 'UniformOut',0);

assignin('base','meanStacks',meanStacks)

signalMap = 1;
end

