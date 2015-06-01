function [matrixMap] = RetinoMapper( imExp, chNumber, runState)
% RetinoMapper determines the retnotopic positon of a recording site for an
% imExp with gridded grating as the stimulus type. The method is to comoute
% over several trials the average stack for each grating position and then
% to calculate dfByF for each pixel in the image stack during visual
% stimulation. A montage of the maximum dfByF image for each position of
% the grating is displayed to the screen so the user can determine the
% retinotopic location of their recording site.
%
%INPUTS:                    : imExp, a structure containing all corrected
%                             images, stimulus information etc.
%                           : chNumber, ch to anlayze for retinotopy
%
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
%%%%%%%%%%%%%%% CALL FLUORMAP TO CONSTRUCT IMAGES MAP OBJ %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[imagesMap, ~, ~] = fluorMapV2(imExp,'Position', chNumber, [], runState);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% CALCULATE MEAN STACK FOR EACH KEY %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get cell of images from values of the map
mappedImages = imagesMap.values;
% concatenate the 3d stacks along the fourth dim and compute the mean for
% each cell in the mappedImages Cell array
meanStacks = cellfun(@(t) mean(cat(4,t{:}),4), cellfun(@(y) y,...
                       mappedImages, 'UniformOut',0), 'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% CALCULATE THE PRESTIMULUS AVERAGE %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute the mean for each cell in meanStacks for frames = 1:lastFrame
% before stimulus starts

% Need to obtain the following from imExp
frameRate = imExp.fileInfo.imageFrameRate;
stimTiming = imExp.stimulus(1,1).Timing;
% now compute mean
preStimAvgFrames = cellfun(@(t) ...
            mean(t(:,:,1:floor(frameRate*stimTiming(1))),3), meanStacks,...
            'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% CALCULATE THE STIMULUS AVERAGE %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute the mean for each cell in meanStacks for frames = 
% lastPreStimFrame:lastStimulusFrame
stimAvgFrames = cellfun(@(t) mean(t(:,:,floor(frameRate*stimTiming(1)):...
        floor(frameRate*(stimTiming(1)+stimTiming(2)))),3), meanStacks,...
        'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% CALCULATE DIFFERENCE OF PRESTIM AND STIMULUS MEANS %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
diffedAvgFrames = cellfun(@minus, stimAvgFrames, preStimAvgFrames,...
                           'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                       


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% REORGANIZE AVG DIFFERENCE FRAMES %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now will organize the difference frames into the number of rows x
% numCols of the stimulus and show a montage of all difference frames
% Determine the number of rows and columns stimulus was shown over
numCols = max([imExp.stimulus(:,:).Columns]);
numRows = max([imExp.stimulus(:,:).Rows]);
% compute the size of the images (assuming here they are square)
matSize = size(diffedAvgFrames{1},1);

% concatenate all the cells together along cols [a,b,c,...]
catMatrices = [diffedAvgFrames{:}];

%use mat2cell to convert to a cell with elements 
% construct an array that will hold the coulumn sizes
colArrays = numCols*matSize*ones(1,numRows);
% call mat2cell to construct a cell array where the elements are the
% rowMatrices
rowCell = mat2cell(catMatrices,[matSize],colArrays);
% vertically concatenate the rows together to form a larger organized
% matrix
matrixMap = vertcat(rowCell{:});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% DISPLAY MONTAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% call imshow
%imshow(orgMatrices, [0,max(max(orgMatrices)/scaleFactor)])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end