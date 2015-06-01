function evokedMovieStack( imageStack, stimulusTiming, acqFrameRate,...
                           scaleFactor, framesPerSec, repeats )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
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
%%%%%%%%%%%%%%%%%%%%%% CALCULATE PRESTIMULUS AVERAGE %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine the class of the incoming image stack
imageClass = class(imageStack);
% extract the prestimulus frames
preStimFrames = imageStack(:,:,1:floor(stimulusTiming(1)*acqFrameRate));
% compute the mean of the prestimulus frames
meanPreStimFrame = mean(preStimFrames,3);
% convert back to uint16
meanPreStimFrame = cast(meanPreStimFrame, imageClass);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% COMPUTE EVOKED STACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for frame=1:size(imageStack,3)
    evokedStack(:,:,frame) = imageStack(:,:,frame)-meanPreStimFrame;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% OPEN FIGURE AND SET AXIS PROPS %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the rendering method as OpenGL since most pcs feature hardware
% acceleration for this renderer. Note if running on a MAC set the rederer
% to zbuffer since OpenGL is not available
hfig = figure('Renderer','zbuffer');
% Set the axis tight to the images
axis tight;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% RENDER THE MOVIE AND SAVE FRAMES %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The process of creating a movie involves 2-steps. First we must render 
% the movie with the graphics hardware and use get frame to capture each
% image in the figure for future replay.

% Loop through our image stack (along d3), scale the images using
% scaleFactor and magnify the image to double original size
for i=1:size(evokedStack,3)
    imshow(evokedStack(:,:,i),[0 max(max(max(evokedStack)))/scaleFactor],...
                     'initialmagnification',200)
    % Create a frame text box to be displayed on each image (note
    % positioning is in pixel units)
    ht = text(size(evokedStack,2)/2-15,size(evokedStack,1)-10,...
                ['Frame:',num2str(i),'/',num2str(size(evokedStack,3))]);
            
    % set the color of frame text to  if pre and post stimulus
    if i/acqFrameRate < stimulusTiming(1) ||...
            i/acqFrameRate > stimulusTiming(1) + stimulusTiming(2) 
        set(ht,'color',[.5 .5 .5],'FontSize',12);
    else
        set(ht,'color', [1 1 0],'FontSize',12)
    end
    % call get frame to capture the current image shown in the figure and
    % save to mov
    mov(i) = getframe;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLAY THE MOVIE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now play the movie 3 times at frames/sec specified by user
movie(mov,repeats,framesPerSec)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CLOSE THE FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the figure was not closed by the user then we will autoclose the
% figure to prevent conflicts with other programs displaying figures
% Check whether figure handle exist, if so close the figure
if ishandle(hfig)
    close(hfig)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

