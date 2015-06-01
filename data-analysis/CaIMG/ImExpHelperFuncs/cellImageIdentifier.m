function cellImageIdentifier(expFileInfo, imagePath, trialSetNumber,...
                             triggerNumber,...
                             frameNumber, chsToDisplay, imageScaleFactor,...
                             chScaleFactor)
% cellImageIdentifier displays a composite image of all channels specified
% in chsToDisplay. It attempts to use imfuse which is available only on
% Matlab image Processing toolbox version 8 and higher.
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
% INPUTS:              expFileInfo, fileInfo structure from an imExp 
%                      trialSetNumber, the stimulus fileNumber in the
%                                       imExp
%                       triggerNumber, trigger number to image
%                       frameNumber, frame to display
%                       chsToDisplay, vector of 2 numbers for chs to be
%                                     imaged
%                       imageScaleFactor, scaling factor for images
%                       (bothChs)
%                       chScaleFactor, allows independent scaling of chs. 2
%                       el vector 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% OBTAIN THE IMAGE STACK NAME AND IMAGE PATH %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
imageStackName = expFileInfo(trialSetNumber).imageFileNames{triggerNumber};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% CALL THE TIFFLOADER PASSING IN CHSTODISPLAY %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[stackExtrema, tiffCell] = tiffLoader(imagePath, imageStackName,...
                                      chsToDisplay);
assignin('base','tiffCellOut',tiffCell)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% RESCALE IMAGES TO STACK EXTREMA %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will now determine the maximum image intensity pixel across all the
% channels and rescale all the images to be in the range [0,256]. This is
% necessary becasue we will eventually call imfuse to fuse our images which
% will convert them and wrongly rescale them if we don't provide uint8
% input.
maxIntensity =  max([stackExtrema{:}]);
% now apply the users scaleFactor
displayIntensity = maxIntensity/imageScaleFactor;

% Now determine the rescale factor 
rescaleFactor = double(round(displayIntensity/256));

rescaledImagesCell = cellfun(@(x) uint8(x./rescaleFactor), tiffCell,...
                              'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% FUSE THE IMAGES FOR THE GIVEN FRAME %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% we call imfuse if we have the right version of the image processing
% toolbox
if verLessThan('images', '8.0')
   % if the matlab version does not support the imfuse function just plot
   % the chsToDisplay separately. Start by getting the number of figures
   % and open up two more
   numFigs=length(findall(0,'type','figure'));
   figure(numFigs+1)
    imshow(tiffCell{chsToDisplay(1)}(:,:,frameNumber),...
           stackExtrema(1)/imageScaleFactor);
   figure(numFigs+2)
           imshow(tiffCell{chsToDisplay(2)}(:,:,frameNumber),...
                  stackExtrema(1)/imageScaleFactor);
   
else
    % We call imfuse and plot to a new figure
    fusedIm = imfuse(...
 rescaledImagesCell{chsToDisplay(1)}(:,:,frameNumber).*chScaleFactor(1),...
  rescaledImagesCell{chsToDisplay(2)}(:,:,frameNumber).*chScaleFactor(2),...
                 'falseColor','Scaling','none','ColorChannels',[1 2 0]);
    numFigs=length(findall(0,'type','figure'));
    figure(numFigs+1)
    imshow(fusedIm,'InitialMagnification', 200)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             
             


end

