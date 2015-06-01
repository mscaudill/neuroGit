function [tiffMatrix, acquisitionsToDrop] = ...
                                        ccdTiffLoader(acqTime, stimTime,...
                                                     frameRate,...
                                                     numStimuli,...
                                                     tiffFile, ...
                                                     numFirstAcqFrameDrops)
%ccdTiffLoader loads a tiffFile captured by a qimaging ccd camera, It uses
%the user inputed number of frames dropped during the first acqusition and
%the timing difference between all frames across all acquistions to locate
%and revove acquisitions with dropped frames. For example if the tiff file
%is made up of twelve acqusitions (eg. 12 orientatations) and 70 frames
%were collected for each acqusition and the 71st and 72nd frame were
%dropped, ccdTiffLoader will return a tiffMatrix where the 71-140 frames
%corresponding the second acqusition have been removed.
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
%%%%%%%%%%%%%%%%%%% GET TIFF FILE HEADER METADATA %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Call imfinfo to get the header of the tiff file
infoImage = imfinfo(tiffFile);
% get the image dimensions
imageWidth = infoImage(1).Width;
imageHeight = infoImage(1).Height;
numImages = length(infoImage);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% CHECK FOR DROPPED FRAMES %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the number of theoretical images calculated from the acqTime and
% frameRate do not match the actual number of images we have dropped
% frame(s).
numExpectedFrames = acqTime*frameRate*numStimuli;
numDroppedFrames = numExpectedFrames-numImages;

if numDroppedFrames > 0;
    % We need to locate which frames where dropped. We will do this by
    % calculating the timing difference between individual frames.
    % obtain all the frame times from the tiffHeader
    frameTimesStrs = {infoImage.DateTime};
    % convert each frame time string to a date vector with ms accuracy
    frameTimes = datevec(frameTimesStrs,'mm/dd/yyyy HH:MM:SS.FFF');
    
    % check for missing frames using etime function (matlab built-in)
    for frame = 1:numImages-1
        frameTimeDiffs(frame) =...
            etime(frameTimes(frame+1,:),frameTimes(frame,:));
    end
   assignin('base','frameTimeDiffs',frameTimeDiffs)
    % We expect that the timing difference between individual frames
    % should be 1/frameRate (ex 5Hz gives 200 ms between frames. We also
    % expect a timing difference of stimTim-AcqTime. This times correspond
    % to the intraburst and interburst intervals of the function genertator
    % used to trigger the CCD camera. If there are frameTimeDiffs that are
    % greater than 1/frameRate and less than the interburst interval then
    % that frame was dropped
    intraburstInterval = 1/frameRate + .05; % we add a 50 msec cushion
    interburstInterval = sum(stimTime)-acqTime-.05; % add a 50 msec cushion
    
    % locate the idxs of the dropped frames (NOTE THIS DOES NOT HANDLE
    % CONSECUTIVE FRAME DROPS FOR ACQNUMBER > 1: IF THIS OCCURS THIS CODE
    % WILL NEED TO BE MODIFIED!!!). For acq #1 it will be ok since the user
    % specifies the exact number of frame drops but for acq>1 it will not
    % work since it treats consectuive frame drops as a single frame drop.
    % A way to ensure this is to look at the frameTimeDiffs array out put
    % by this function using hist if there are frameTime diffs > 2*frame
    % rate not occurring in the first acqusition then this needs to be
    % addressed or the data thrown out.
    droppedFrameIdxs = find(frameTimeDiffs > intraburstInterval &...
                            frameTimeDiffs < interburstInterval);
                        
    % We now need to handle two special cases, if the first frame(s) was
    % dropped or frames were dropped on the last frame of the last
    % acquisition
    if numFirstAcqFrameDrops > 0
        droppedFrameIdxs(1:numFirstAcqFrameDrops)=1:numFirstAcqFrameDrops;
    end
    
    % we will now count the total number of frame drops in dropped
    % frameIdxs if it matches numFrameDrops (line 28) then we can keep
    % the last set otherwise we missed the last frame and we must
    % remove the last acquisition
    if numel(droppedFrameIdxs) < numDroppedFrames
        % then we set the last frame as being dropped so the last
        % acqusiton will be removed
        droppedFrameIdxs(numel(frameTimeDiffs)) = 1;
    end
    
    %  we simply locate the dropped frame and remove all the frames for 
    % that acquisition.
    % Find the acquisition where the frame was dropped. Note we use max
    % here to take care of case in which the first aqusition is to be
    % dropped and floor gives 0.
    allAcquisitionsToDrop  =...
        max(floor(droppedFrameIdxs/(acqTime*frameRate)),1);
    
    % if mulitple frames were dropped for a particular acquisition, we only
    % need the first occurence since we will be dropping all the frames
    % for that acquisition anyway. Use unique on aquistionsToDrop.
    acquisitionsToDrop = unique(allAcquisitionsToDrop);
    
    % we also need to know the number of frames dropped in each aqusition
    % so we remove the correct number of frames. Use histc
    numDroppedFramesInAcq = histc(allAcquisitionsToDrop,...
                            unique(allAcquisitionsToDrop));
    
    % We now will calculate the frames to drop in each acqusition. Since
    % multiple frames may have been dropped in a single acquisition we will
    % remove numDroppedFramesInAcq
    for acq = 1:numel(acquisitionsToDrop)
        framesToDrop{acq} = acq*acqTime*frameRate-acqTime*frameRate:1:...
                          acq*acqTime*frameRate-numDroppedFramesInAcq(acq);
    end
                
    % correct framesToDrop if acqusition 1 is present. If acqusition 1 is
    % present above then the first frames to drop will go from 0:numFrames
    % (if one frame dropped). Since the first frame should be 1 and the
    % last frame to remove numFrames-1 we correct that here
    if ismember(1,acquisitionsToDrop)
        framesToDrop{1} = 1:frameRate*acqTime-numDroppedFramesInAcq(1);
    end
    
else % if all the frames are present then no need to drop any frames.
    framesToDrop={[]};
    acquisitionsToDrop = 0;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% LOAD THE TIFF AND DROP APPR. FRAMES %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now ready to load the tiff file into a matrix and drop the
% appropriate acqusitions in which a frame(s) was dropped.

%Initialize the tiff matrix 
tiffMatrix = zeros(imageWidth, imageHeight ,numImages, 'uint16');

% Call imread passing iminfo to speed up the process
for image = 1:numImages
    tiffMatrix(:,:,image)=imread(tiffFile,'tiff','Index',image,...
        'Info',infoImage);
end
assignin('base','framesToDrop',framesToDrop)   
% now drop the appropriate frames from tiffMatrix
tiffMatrix(:,:,[framesToDrop{:}]) = [];




end

