function optoResponse(droppedStacks, chNumber, currentRoi,...
                                  baselineFrames, neuropilRatio)
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
numTrials = size(imagesStruct,2);
numTriggers = size(imagesStruct,1);

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
for trial = 1:numTrials
    % get the number of laser only triggers numTriggers/2
    groupedImages{trial} = {imagesCell{1:numTriggers/2}};
    % pop off the first numTriggers/2 after extracting group
    imagesCell(1:numTriggers/2)=[];
end
assignin('base','groupedImages',groupedImages)
% concatenate trials along 4th dim
groupedImages = cellfun(@(x) cat(4,x{:}), groupedImages, 'UniformOut',0);

% lastly compute the mean along the 4th dim
meanStacks = cellfun(@(x) mean(x,4), groupedImages, 'UniformOut',0);

assignin('base','meanStacks',meanStacks)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% COMPUTE THE ROI LOGICAL MASK %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are going to create a logical image for the roi that matches the
% width and height of each of our collected data frames so first get the
% width and height of images in the imExp
imageDim = size(droppedStacks(1,1).(['Ch',num2str(chNumber)]));

roi = currentRoi;

% create a logial image mask for the input current roi
roiImage = logical(poly2mask(roi(:,1),roi(:,2),...
                     imageDim(1), imageDim(2)));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% COMPUTE NEUROPIL ANNULAR REGION %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now will create a neuropil region for the roi. To do this we will get
% the center and max radius of each roi and construct an annulus from two
% circles. The inner circle will match the max radius of the roi and the
% outer circle will be 20 um greater in diameter.

% determine the center for the roi by taking the mean of all the xs and ys
center = [mean(roi(:,1)), mean(roi(:,2))];
% the radius will be the maximum difference of the roi points from the
% center
radius = max(sqrt((roi(:,1)-center(1)).^2 + (roi(:,2)-center(2)).^2));

% now create inner and outer circles to create an annular region
radians = linspace(0, 2*pi, 100);
innerCircle = [center(1)+radius*cos(radians); ...
               center(2)+radius*sin(radians)]';

radiusGrowthPercent = 0.2;

outerCircle = [center(1)+(1+radiusGrowthPercent)*radius*cos(radians);...
               center(2)+(1+radiusGrowthPercent)*radius*sin(radians)]';

% create a logical image of the neuropil annular region
neuropilLogicalImage = ...
    logical(poly2mask(outerCircle(:,1), outerCircle(:,2), imageDim(1),...
    imageDim(2)) - poly2mask(innerCircle(:,1), innerCircle(:,2),...
    imageDim(1), imageDim(2)));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% MULTIPLY DATA STACKS WITH LOGICAL STACKS %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the image class of the dropped stacks
imageClass = class(meanStacks{1});

% recast the roi and neuropil logical images to match the imageClass
roiImage = cast(roiImage,imageClass);
neuropilImage = cast(neuropilLogicalImage,imageClass);
           
% We will now convert the combined images into stacks for matrix
% multiplication with each stack in the imagesMap
roiStack = repmat(roiImage,[1,1, imageDim(3)]);
neuropilStack = repmat(neuropilImage, [1,1,imageDim(3)]);

for stack = 1:numel(meanStacks)
    roiImageStacks{stack} = roiStack.*meanStacks{stack};
    neuropilImageStacks{stack} = neuropilStack.*meanStacks{stack};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% COMPUTE FLUORESCENCE VALUES %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fluorVals = cellfun(@(x) squeeze(mean(mean(x))), roiImageStacks, 'UniformOut',0);
neuropilVals = cellfun(@(x) squeeze(mean(mean(x))), neuropilImageStacks,...
                        'UniformOut',0);
                    
corrFluorVals = cellfun(@(x,y) x-neuropilRatio*y,...
                        fluorVals,neuropilVals,'UniformOut',0);

assignin('base', 'corrFluorVals',corrFluorVals)

% call deltaFbyF to calculate percentage changes
for arr = 1:numel(fluorVals)
    dFbyF{arr} = deltaFbyF(fluorVals{arr}, corrFluorVals{arr},[],[],...
                              baselineFrames);
end
numFigs = length(findall(0,'type','figure'));
figure(numFigs+1)
dFbyFmatrix = cell2mat(dFbyF);
plot(dFbyFmatrix)

end

